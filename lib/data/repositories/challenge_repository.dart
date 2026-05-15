import 'package:habitflow/data/models/challenge_model.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ChallengeRepository {
  static const _kBox = 'challenges_v1';

  Box<ChallengeModel> get _box => Hive.box<ChallengeModel>(_kBox);
  final _client = Supabase.instance.client;

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ChallengeModelAdapter());
    }
    await Hive.openBox<ChallengeModel>(_kBox);
  }

  // ── Local reads ───────────────────────────────────────────────────────────
  List<Challenge> getAll() => _box.values.map(_map).toList()
    ..sort((a, b) => b.startDate.compareTo(a.startDate));

  List<Challenge> getActive() =>
      getAll().where((c) => c.status == ChallengeStatus.active).toList();

  List<Challenge> getCompleted() =>
      getAll().where((c) => c.status == ChallengeStatus.completed).toList();

  List<Challenge> getFailed() =>
      getAll().where((c) => c.status == ChallengeStatus.failed).toList();

  Challenge? getById(String id) {
    final m = _box.get(id);
    return m != null ? _map(m) : null;
  }

  // ── Create ────────────────────────────────────────────────────────────────
  Future<Challenge> create({
    required String title,
    required String description,
    required String emoji,
    required List<String> habitIds,
    required int targetDays,
    required int colorIndex,
  }) async {
    final m = ChallengeModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      emoji: emoji,
      habitIds: habitIds,
      targetDays: targetDays,
      startDate: DateTime.now(),
      colorIndex: colorIndex,
      statusIndex: 0,
      isSynced: false,
    );
    await _box.put(m.id, m);
    return _map(m);
  }

  // ── Update status ─────────────────────────────────────────────────────────
  Future<Challenge> updateStatus(String id, ChallengeStatus status) async {
    final m = _box.get(id);
    if (m == null) throw StateError('Challenge not found: $id');
    m.statusIndex = status.index;
    m.completedDate =
        status == ChallengeStatus.completed ? DateTime.now() : null;
    m.isSynced = false;
    m.updatedAt = DateTime.now();
    await m.save();
    return _map(m);
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> delete(String id) async {
    await _box.delete(id);
    try {
      await _client.from('challenges').delete().eq('id', id);
    } catch (_) {}
  }

  // ── Evaluate ─────────────────────────────────────────────────────────────
  /// Checks all active challenges against current streaks.
  /// Marks completed if all habit streaks >= targetDays.
  /// Marks failed if elapsed days > targetDays + grace(1).
  Future<List<Challenge>> evaluate(
      Map<String, int> currentStreaksByHabit) async {
    final changed = <Challenge>[];

    for (final m in _box.values.toList()) {
      if (m.statusIndex != ChallengeStatus.active.index) continue;

      final c = _map(m);
      final allStreaksOk = c.habitIds.isNotEmpty &&
          c.habitIds.every(
            (hid) => (currentStreaksByHabit[hid] ?? 0) >= c.targetDays,
          );

      if (allStreaksOk) {
        final updated = await updateStatus(c.id, ChallengeStatus.completed);
        changed.add(updated);
      } else if (c.daysElapsed() > c.targetDays + 1) {
        // Grace period of 1 day before marking failed
        final updated = await updateStatus(c.id, ChallengeStatus.failed);
        changed.add(updated);
      }
    }
    return changed;
  }

  // ── Cloud sync ────────────────────────────────────────────────────────────

  /// Push all unsynced challenges to Supabase.
  Future<void> pushPending(String userId) async {
    final pending = _box.values.where((c) => !c.isSynced).toList();
    if (pending.isEmpty) return;

    final rows = pending.map((m) => _map(m).toSupabase(userId)).toList();
    await _client.from('challenges').upsert(rows, onConflict: 'id');

    for (final m in pending) {
      m.isSynced = true;
      await m.save();
    }
  }

  /// Pull all challenges from Supabase and merge into local.
  Future<void> pullFromCloud(String userId) async {
    final res = await _client
        .from('challenges')
        .select()
        .eq('user_id', userId)
        .order('start_date', ascending: false);

    final remotes = (res as List)
        .map((j) => Challenge.fromSupabase(j as Map<String, dynamic>))
        .toList();

    for (final r in remotes) {
      if (!_box.containsKey(r.id)) {
        final m = ChallengeModel(
          id: r.id,
          title: r.title,
          description: r.description,
          emoji: r.emoji,
          habitIds: r.habitIds,
          targetDays: r.targetDays,
          startDate: r.startDate,
          completedDate: r.completedDate,
          statusIndex: r.status.index,
          colorIndex: r.colorIndex,
          isSynced: true,
          updatedAt: r.updatedAt,
        );
        await _box.put(m.id, m);
      } else {
        // Server wins if newer
        final local = _box.get(r.id)!;
        final serverTs = r.updatedAt ?? r.startDate;
        final localTs = local.updatedAt ?? local.startDate;
        if (serverTs.isAfter(localTs)) {
          local.title = r.title;
          local.description = r.description;
          local.emoji = r.emoji;
          local.habitIds = r.habitIds;
          local.targetDays = r.targetDays;
          local.completedDate = r.completedDate;
          local.statusIndex = r.status.index;
          local.colorIndex = r.colorIndex;
          local.isSynced = true;
          local.updatedAt = r.updatedAt;
          await local.save();
        }
      }
    }
  }

  /// Full sync: push local → pull remote.
  Future<void> fullSync(String userId) async {
    await pushPending(userId);
    await pullFromCloud(userId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Challenge _map(ChallengeModel m) => Challenge(
        id: m.id,
        title: m.title,
        description: m.description,
        emoji: m.emoji,
        habitIds: List<String>.from(m.habitIds),
        targetDays: m.targetDays,
        startDate: m.startDate,
        completedDate: m.completedDate,
        status: ChallengeStatus.values[m.statusIndex],
        colorIndex: m.colorIndex,
        isSynced: m.isSynced,
        updatedAt: m.updatedAt,
      );
}
