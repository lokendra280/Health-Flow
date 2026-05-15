import 'package:habitflow/core/utils/sync_service.dart';
import 'package:habitflow/data/models/checkin_model.dart';
import 'package:habitflow/data/models/habit_model.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class HabitRepository {
  static const _kHabits = 'habits_v1';
  static const _kCheckins = 'checkins_v1';

  Box<HabitModel> get _habits => Hive.box<HabitModel>(_kHabits);
  Box<CheckinModel> get _checkins => Hive.box<CheckinModel>(_kCheckins);

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitModelAdapter());
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(CheckinModelAdapter());
    await Hive.openBox<HabitModel>(_kHabits);
    await Hive.openBox<CheckinModel>(_kCheckins);
  }

  // ── Habits ────────────────────────────────────────────────────────────────
  List<Habit> getHabits() =>
      _habits.values.where((h) => h.isActive).map(_mH).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<Habit> addHabit({
    required String name,
    required String icon,
    required int targetPerDay,
    required int colorIndex,
  }) async {
    final m = HabitModel(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      targetPerDay: targetPerDay,
      createdAt: DateTime.now(),
      colorIndex: colorIndex,
      isSynced: false,
    );
    await _habits.put(m.id, m);
    return _mH(m);
  }

  Future<Habit> updateHabit(Habit h) async {
    final m =
        _habits.get(h.id) ?? (throw StateError('Habit not found: ${h.id}'));
    m
      ..name = h.name
      ..icon = h.icon
      ..targetPerDay = h.targetPerDay
      ..colorIndex = h.colorIndex
      ..isSynced = false
      ..updatedAt = DateTime.now();
    await m.save();
    return _mH(m);
  }

  Future<void> deleteHabit(String id) async {
    final m = _habits.get(id);
    if (m != null) {
      m
        ..isActive = false
        ..isSynced = false;
      await m.save();
    }
  }

  // ── Checkins ──────────────────────────────────────────────────────────────
  List<Checkin> getAllCheckins({String? habitId}) {
    var all = _checkins.values.map(_mC).toList();
    if (habitId != null) all = all.where((c) => c.habitId == habitId).toList();
    return all;
  }

  List<Checkin> getTodayCheckins({String? habitId}) {
    final today = _dk(DateTime.now());
    return getAllCheckins(habitId: habitId)
        .where((c) => c.dateKey == today)
        .toList();
  }

  /// Returns checkins for a specific date key (yyyy-MM-dd),
  /// optionally filtered by [habitId]. Primary method name in Phase 3.
  List<Checkin> getCheckinsForDate(String dateKey, {String? habitId}) {
    return getAllCheckins(habitId: habitId)
        .where((c) => c.dateKey == dateKey)
        .toList();
  }

  /// Alias for [getCheckinsForDate].
  /// Keeps any code calling getCheckinsForDay() working without changes.
  List<Checkin> getCheckinsForDay(String dateKey, {String? habitId}) =>
      getCheckinsForDate(dateKey, habitId: habitId);

  Future<Checkin> checkIn(String habitId) async {
    final m = CheckinModel(
      id: _uuid.v4(),
      habitId: habitId,
      timestamp: DateTime.now(),
      isSynced: false,
    );
    await _checkins.put(m.id, m);
    return _mC(m);
  }

  // ── Streak ────────────────────────────────────────────────────────────────
  Streak calculateStreak(String habitId) {
    final dates = _checkins.values
        .where((c) => c.habitId == habitId)
        .map((c) => _dk(c.timestamp))
        .toSet()
        .toList()
      ..sort();

    if (dates.isEmpty) {
      return Streak(habitId: habitId, currentStreak: 0, longestStreak: 0);
    }

    int longest = 1, run = 1;
    for (int i = 1; i < dates.length; i++) {
      if (_dd(dates[i - 1], dates[i]) == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }

    final today = _dk(DateTime.now());
    final yest = _dk(DateTime.now().subtract(const Duration(days: 1)));
    int current = 0;
    if (dates.last == today || dates.last == yest) {
      current = 1;
      for (int i = dates.length - 2; i >= 0; i--) {
        if (_dd(dates[i], dates[i + 1]) == 1)
          current++;
        else
          break;
      }
    }

    return Streak(
      habitId: habitId,
      currentStreak: current,
      longestStreak: longest,
      totalCheckins: _checkins.values.where((c) => c.habitId == habitId).length,
      lastCheckinDate: _checkins.values
          .where((c) => c.habitId == habitId)
          .map((c) => c.timestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

  // ── Cloud sync ────────────────────────────────────────────────────────────
  Future<void> syncWithCloud(String userId, SyncService sync) async {
    final merged = await sync.fullSync(
      userId: userId,
      localHabits: getHabits(),
      localCheckins: getAllCheckins(),
    );

    for (final h in merged.habits) {
      await _habits.put(
          h.id,
          HabitModel(
            id: h.id,
            name: h.name,
            icon: h.icon,
            targetPerDay: h.targetPerDay,
            createdAt: h.createdAt,
            colorIndex: h.colorIndex,
            isActive: h.isActive,
            isSynced: true,
            updatedAt: h.updatedAt,
          ));
    }

    for (final c in merged.checkins) {
      if (!_checkins.containsKey(c.id)) {
        await _checkins.put(
            c.id,
            CheckinModel(
              id: c.id,
              habitId: c.habitId,
              timestamp: c.timestamp,
              isSynced: true,
            ));
      }
    }
  }

  Future<void> pushPending(String userId, SyncService sync) async {
    await sync.pushHabits(
        userId, _habits.values.where((h) => !h.isSynced).map(_mH).toList());
    await sync.pushCheckins(
        userId, _checkins.values.where((c) => !c.isSynced).map(_mC).toList());

    for (final m in _habits.values.where((h) => !h.isSynced)) {
      m.isSynced = true;
      await m.save();
    }
    for (final m in _checkins.values.where((c) => !c.isSynced)) {
      m.isSynced = true;
      await m.save();
    }
  }

  // ── Seed ──────────────────────────────────────────────────────────────────
  Future<void> seedDefaults() async {
    if (_habits.isNotEmpty) return;
    const seeds = [
      ('Morning Run', '🏃', 1, 0),
      ('Read 20 Pages', '📚', 1, 1),
      ('Drink 8 Glasses', '💧', 8, 2),
      ('Meditate', '🧘', 1, 3),
    ];
    for (final (name, icon, t, ci) in seeds) {
      await addHabit(name: name, icon: icon, targetPerDay: t, colorIndex: ci);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  Habit _mH(HabitModel m) => Habit(
        id: m.id,
        name: m.name,
        icon: m.icon,
        targetPerDay: m.targetPerDay,
        createdAt: m.createdAt,
        isActive: m.isActive,
        colorIndex: m.colorIndex,
        isSynced: m.isSynced,
        updatedAt: m.updatedAt,
      );

  Checkin _mC(CheckinModel m) => Checkin(
        id: m.id,
        habitId: m.habitId,
        timestamp: m.timestamp,
        isSynced: m.isSynced,
      );

  String _dk(DateTime d) => '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  int _dd(String a, String b) =>
      DateTime.parse(b).difference(DateTime.parse(a)).inDays;
}
