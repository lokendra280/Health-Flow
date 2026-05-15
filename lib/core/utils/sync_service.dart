import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/entities.dart';

class SyncService {
  final _client = Supabase.instance.client;
  final _connectivity = Connectivity();
  StreamSubscription? _sub;
  bool _online = false;

  bool get isOnline => _online;

  Future<void> init() async {
    final r = await _connectivity.checkConnectivity();
    _online = r != ConnectivityResult.none;
    _sub = _connectivity.onConnectivityChanged.listen((r) {
      _online = r != ConnectivityResult.none;
    });
  }

  void dispose() => _sub?.cancel();

  Future<void> pushHabits(String userId, List<Habit> habits) async {
    if (!_online || habits.isEmpty) return;
    await _client.from('habits').upsert(
        habits.map((h) => h.toSupabase(userId)).toList(),
        onConflict: 'id');
  }

  Future<void> pushCheckins(String userId, List<Checkin> checkins) async {
    if (!_online || checkins.isEmpty) return;
    await _client.from('checkins').upsert(
        checkins.map((c) => c.toSupabase(userId)).toList(),
        onConflict: 'id');
  }

  Future<List<Habit>> pullHabits(String userId) async {
    if (!_online) return [];
    final res = await _client
        .from('habits')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at');
    return (res as List)
        .map((j) => Habit.fromSupabase(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<Checkin>> pullCheckins(String userId, {DateTime? since}) async {
    if (!_online) return [];
    var q = _client.from('checkins').select().eq('user_id', userId);
    if (since != null) q = q.gte('checked_at', since.toIso8601String());
    final res = await q.order('checked_at');
    return (res as List)
        .map((j) => Checkin.fromSupabase(j as Map<String, dynamic>))
        .toList();
  }

  Future<({List<Habit> habits, List<Checkin> checkins})> fullSync({
    required String userId,
    required List<Habit> localHabits,
    required List<Checkin> localCheckins,
  }) async {
    if (!_online) return (habits: localHabits, checkins: localCheckins);

    await pushHabits(userId, localHabits.where((h) => !h.isSynced).toList());
    await pushCheckins(
        userId, localCheckins.where((c) => !c.isSynced).toList());

    final remoteHabits = await pullHabits(userId);
    final remoteCheckins = await pullCheckins(userId);

    final habitMap = <String, Habit>{for (final h in localHabits) h.id: h};
    final checkinMap = <String, Checkin>{
      for (final c in localCheckins) c.id: c
    };
    for (final h in remoteHabits) habitMap[h.id] = h;
    for (final c in remoteCheckins) checkinMap[c.id] = c;

    return (
      habits: habitMap.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      checkins: checkinMap.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
    );
  }

  Future<void> deleteHabit(String habitId) async {
    if (!_online) return;
    await _client.from('habits').update({'is_active': false}).eq('id', habitId);
  }
}
