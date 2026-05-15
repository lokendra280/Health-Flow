import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/notification_service.dart';
import 'package:habitflow/data/models/reminder_model.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class ReminderRepository {
  static const _kBox = 'reminders_v1';

  Box<ReminderModel> get _box => Hive.box<ReminderModel>(_kBox);
  final _client = Supabase.instance.client;

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ReminderModelAdapter());
    }
    await Hive.openBox<ReminderModel>(_kBox);
  }

  // ── Local reads ───────────────────────────────────────────────────────────
  List<Reminder> getAll() => _box.values.map(_map).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<Reminder> forHabit(String habitId) =>
      _box.values.where((r) => r.habitId == habitId).map(_map).toList();

  Reminder? getById(String id) {
    final m = _box.get(id);
    return m != null ? _map(m) : null;
  }

  // ── Create ────────────────────────────────────────────────────────────────
  Future<Reminder> add({
    required String habitId,
    required TimeOfDay time,
    required ReminderFrequency frequency,
    required List<int> customDays,
    required String message,
  }) async {
    final m = ReminderModel(
      id: _uuid.v4(),
      habitId: habitId,
      timeHour: time.hour,
      timeMinute: time.minute,
      frequencyIndex: frequency.index,
      customDays: customDays,
      message: message,
      createdAt: DateTime.now(),
      isEnabled: true,
      isSynced: false,
    );
    await _box.put(m.id, m);
    return _map(m);
  }

  // ── Toggle enabled ────────────────────────────────────────────────────────
  Future<Reminder> toggle(String id) async {
    final m = _box.get(id);
    if (m == null) throw StateError('Reminder not found: $id');
    m.isEnabled = !m.isEnabled;
    m.isSynced = false;
    m.updatedAt = DateTime.now();
    await m.save();

    if (!m.isEnabled) await NotificationService.cancelReminder(id);
    return _map(m);
  }

  // ── Update ────────────────────────────────────────────────────────────────
  Future<Reminder> update({
    required String id,
    TimeOfDay? time,
    ReminderFrequency? frequency,
    List<int>? customDays,
    String? message,
    bool? isEnabled,
  }) async {
    final m = _box.get(id);
    if (m == null) throw StateError('Reminder not found: $id');
    if (time != null) {
      m.timeHour = time.hour;
      m.timeMinute = time.minute;
    }
    if (frequency != null) m.frequencyIndex = frequency.index;
    if (customDays != null) m.customDays = customDays;
    if (message != null) m.message = message;
    if (isEnabled != null) m.isEnabled = isEnabled;
    m.isSynced = false;
    m.updatedAt = DateTime.now();
    await m.save();
    return _map(m);
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> delete(String id) async {
    await NotificationService.cancelReminder(id);
    await _box.delete(id);
    // Also delete from Supabase if online
    try {
      await _client.from('reminders').delete().eq('id', id);
    } catch (_) {}
  }

  Future<void> deleteForHabit(String habitId) async {
    final toDelete = _box.values.where((r) => r.habitId == habitId).toList();
    for (final r in toDelete) {
      await NotificationService.cancelReminder(r.id);
      await r.delete();
    }
    try {
      await _client.from('reminders').delete().eq('habit_id', habitId);
    } catch (_) {}
  }

  // ── Cloud Sync ────────────────────────────────────────────────────────────

  /// Push all unsynced reminders to Supabase.
  Future<void> pushPending(String userId) async {
    final pending = _box.values.where((r) => !r.isSynced).toList();
    if (pending.isEmpty) return;

    final rows = pending.map((m) => _map(m).toSupabase(userId)).toList();
    await _client.from('reminders').upsert(rows, onConflict: 'id');

    for (final m in pending) {
      m.isSynced = true;
      await m.save();
    }
  }

  /// Pull all reminders from Supabase and merge into local.
  Future<void> pullFromCloud(String userId) async {
    final res = await _client
        .from('reminders')
        .select()
        .eq('user_id', userId)
        .order('created_at');

    final remotes = (res as List)
        .map((j) => Reminder.fromSupabase(j as Map<String, dynamic>))
        .toList();

    for (final r in remotes) {
      if (!_box.containsKey(r.id)) {
        // New from server — write locally
        final m = ReminderModel(
          id: r.id,
          habitId: r.habitId,
          timeHour: r.time.hour,
          timeMinute: r.time.minute,
          frequencyIndex: r.frequency.index,
          customDays: r.customDays,
          message: r.message,
          createdAt: r.createdAt,
          isEnabled: r.isEnabled,
          isSynced: true,
          updatedAt: r.updatedAt,
        );
        await _box.put(m.id, m);
      } else {
        // Server may be newer — update if server updatedAt is later
        final local = _box.get(r.id)!;
        final serverTs = r.updatedAt ?? r.createdAt;
        final localTs = local.updatedAt ?? local.createdAt;
        if (serverTs.isAfter(localTs)) {
          local.timeHour = r.time.hour;
          local.timeMinute = r.time.minute;
          local.frequencyIndex = r.frequency.index;
          local.customDays = r.customDays;
          local.message = r.message;
          local.isEnabled = r.isEnabled;
          local.isSynced = true;
          local.updatedAt = r.updatedAt;
          await local.save();
        }
      }
    }
  }

  /// Full sync: push local → pull remote → reschedule notifications.
  Future<void> fullSync(
    String userId,
    Map<String, String> habitNames,
    Map<String, String> habitIcons,
  ) async {
    await pushPending(userId);
    await pullFromCloud(userId);
    await _rescheduleAll(habitNames, habitIcons);
  }

  Future<void> _rescheduleAll(
    Map<String, String> habitNames,
    Map<String, String> habitIcons,
  ) async {
    final all = getAll();
    await NotificationService.rescheduleAll(all, habitNames, habitIcons);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Reminder _map(ReminderModel m) => Reminder(
        id: m.id,
        habitId: m.habitId,
        time: TimeOfDay(hour: m.timeHour, minute: m.timeMinute),
        frequency: ReminderFrequency.values[m.frequencyIndex],
        customDays: List<int>.from(m.customDays),
        isEnabled: m.isEnabled,
        message: m.message,
        isSynced: m.isSynced,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      );
}
