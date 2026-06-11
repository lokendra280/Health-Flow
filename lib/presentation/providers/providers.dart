// ─────────────────────────────────────────────────────────────────────────────
//  providers.dart  — Phase 3 unified provider file
//  All providers in one place so every screen only needs one import.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/utils/auth_service.dart';
import 'package:habitflow/core/utils/notification_service.dart';
import 'package:habitflow/core/utils/sync_service.dart';
import 'package:habitflow/data/repositories/challenge_repository.dart';
import 'package:habitflow/data/repositories/habit_repository.dart';
import 'package:habitflow/data/repositories/reminder_repository.dart';
import 'package:habitflow/domain/entities/entities.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  UTILITY
// ══════════════════════════════════════════════════════════════════════════════
void unawaited(Future<void> f) => f.catchError((_) {});

// ══════════════════════════════════════════════════════════════════════════════
//  REPOSITORY SINGLETONS
// ══════════════════════════════════════════════════════════════════════════════
final authServiceProvider = Provider<AuthService>((_) => AuthService());
final syncServiceProvider = Provider<SyncService>((_) => SyncService());
final habitRepoProvider = Provider<HabitRepository>((_) => HabitRepository());
final reminderRepoProvider =
    Provider<ReminderRepository>((_) => ReminderRepository());
final challengeRepoProvider =
    Provider<ChallengeRepository>((_) => ChallengeRepository());

// ══════════════════════════════════════════════════════════════════════════════
//  THEME
// ══════════════════════════════════════════════════════════════════════════════
final themeModeProvider = StateProvider<bool>((_) => false);

// ══════════════════════════════════════════════════════════════════════════════
//  AUTH
// ══════════════════════════════════════════════════════════════════════════════
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AppAuthState>((ref) => AuthNotifier(
          ref.watch(authServiceProvider),
          ref.watch(syncServiceProvider),
          ref.watch(habitRepoProvider),
        ));

/// Renamed to AppAuthState to avoid clash with Supabase's AuthState type.
// class AppAuthState {
//   final AuthStatus status;
//   final AppUser? user;
//   final String? error;

//   const AppAuthState({required this.status, this.user, this.error});
//   const AppAuthState.loading()
//       : status = AuthStatus.loading,
//         user = null,
//         error = null;
//   const AppAuthState.unauthenticated()
//       : status = AuthStatus.unauthenticated,
//         user = null,
//         error = null;
//   AppAuthState.authenticated(AppUser u)
//       : status = AuthStatus.authenticated,
//         user = u,
//         error = null;
//   AppAuthState.withError(String e)
//       : status = AuthStatus.unauthenticated,
//         user = null,
//         error = e;
//   bool get isLoading => status == AuthStatus.loading;
//   bool get isAuthenticated => status == AuthStatus.authenticated;
//   bool get isUnauthenticated => status == AuthStatus.unauthenticated;
// }
class AppAuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? error;
  final String? email;

  const AppAuthState({
    required this.status,
    this.user,
    this.error,
    this.email,
  });

  const AppAuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        error = null,
        email = null;

  const AppAuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        error = null,
        email = null;

  AppAuthState.otpSent(String email)
      : status = AuthStatus.otpSent,
        user = null,
        error = null,
        email = email;

  AppAuthState.authenticated(AppUser user)
      : status = AuthStatus.authenticated,
        user = user,
        error = null,
        email = null;

  AppAuthState.withError(String error)
      : status = AuthStatus.unauthenticated,
        user = null,
        error = error,
        email = null;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isOtpSent => status == AuthStatus.otpSent;
}

class AuthNotifier extends StateNotifier<AppAuthState> {
  final AuthService _auth;
  final SyncService _sync;
  final HabitRepository _repo;

  AuthNotifier(this._auth, this._sync, this._repo)
      : super(const AppAuthState.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _sync.init();
    final user = await _auth.getProfile();
    if (user != null) {
      state = AppAuthState.authenticated(user);
      unawaited(_repo.syncWithCloud(user.id, _sync));
    } else {
      state = const AppAuthState.unauthenticated();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    state = const AppAuthState.loading();

    try {
      await _auth.signUp(
        email: email,
        password: password,
        username: username,
      );

      await _auth.sendOtp(email: email);

      state = AppAuthState.otpSent(email);
    } catch (e) {
      state = AppAuthState.withError(_friendly(e));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AppAuthState.loading();
    try {
      final u = await _auth.signIn(email: email, password: password);
      state = AppAuthState.authenticated(u);
      unawaited(_repo.syncWithCloud(u.id, _sync));
    } catch (e) {
      state = AppAuthState.withError(_friendly(e));
    }
  }

  // ── OTP (passwordless / email verification) ──────────────────────────────────
  Future<void> sendOtp(String email) => _auth.sendOtp(
        email: email.trim().toLowerCase(),
      );

  Future<String?> verifyOtp(String email, String otp) async {
    state = const AppAuthState.loading();
    try {
      final user = await _auth.verifyOtp(
        email: email.trim().toLowerCase(),
        otp: otp,
      );

      if (user != null) {
        state = AppAuthState.authenticated(user);
        unawaited(_repo.syncWithCloud(user.id, _sync));
        return null; // ← success
      }

      state = AppAuthState.withError('Verification failed');
      return 'Verification failed';
    } catch (e) {
      state = AppAuthState.withError(e.toString());
      return e.toString();
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AppAuthState.loading();
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      state = AppAuthState.withError(_friendly(e));
    }
  }

  Future<void> sendMagicLink(String email) => _auth.sendMagicLink(email);
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);
  Future<void> updatePassword(String newPassword) =>
      _auth.updatePassword(newPassword);

  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    final u =
        await _auth.updateProfile(username: username, avatarUrl: avatarUrl);
    state = AppAuthState.authenticated(u);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AppAuthState.unauthenticated();
  }

  void clearError() {
    if (!state.isAuthenticated) state = const AppAuthState.unauthenticated();
  }

  String _friendly(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('invalid login')) return 'Incorrect email or password.';
    if (s.contains('already registered'))
      return 'An account with this email already exists.';
    if (s.contains('network') || s.contains('socket'))
      return 'No internet connection.';
    if (s.contains('email')) return 'Please enter a valid email.';
    if (s.contains('password'))
      return 'Password must be at least 6 characters.';
    return 'Something went wrong. Please try again.';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SYNC
// ══════════════════════════════════════════════════════════════════════════════
final syncStateProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) => SyncNotifier(
          ref.watch(syncServiceProvider),
          ref.watch(habitRepoProvider),
          ref.watch(authStateProvider),
        ));

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _sync;
  final HabitRepository _repo;
  final AppAuthState _auth;

  SyncNotifier(this._sync, this._repo, this._auth)
      : super(const SyncState.idle());

  Future<void> syncNow() async {
    final uid = _auth.user?.id;
    if (uid == null) return;
    if (!_sync.isOnline) {
      state = const SyncState(
          status: SyncStatus.offline,
          message: "You're offline. Changes saved locally.");
      return;
    }
    state = const SyncState(status: SyncStatus.syncing);
    try {
      await _repo.syncWithCloud(uid, _sync);
      state = SyncState(status: SyncStatus.success, lastSynced: DateTime.now());
    } catch (e) {
      state = SyncState(status: SyncStatus.error, message: e.toString());
    }
  }

  Future<void> pushPending() async {
    final uid = _auth.user?.id;
    if (uid == null || !_sync.isOnline) return;
    try {
      await _repo.pushPending(uid, _sync);
      state = SyncState(status: SyncStatus.success, lastSynced: DateTime.now());
    } catch (_) {}
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  HABITS
// ══════════════════════════════════════════════════════════════════════════════
final habitListProvider =
    StateNotifierProvider<HabitListNotifier, AsyncValue<List<Habit>>>(
  (ref) => HabitListNotifier(
    ref.watch(habitRepoProvider),
    ref.watch(syncServiceProvider),
    ref.watch(authStateProvider),
  ),
);

class HabitListNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final HabitRepository _repo;
  final SyncService _sync;
  final AppAuthState _auth;

  HabitListNotifier(this._repo, this._sync, this._auth)
      : super(const AsyncValue.loading()) {
    _load();
  }

  void _load() => state = AsyncValue.data(_repo.getHabits());

  // Future<void> addHabit(
  //     {required String name,
  //     required String icon,
  //     required int targetPerDay,
  //     required int colorIndex,
  //     required String reminderTime,
  //     required bool reminderEnabled,
  //     required String frequency}) async {
  //   final habit = await _repo.addHabit(
  //     name: name,
  //     icon: icon,
  //     targetPerDay: targetPerDay,
  //     colorIndex: colorIndex,
  //     reminderTime: reminderTime,
  //     reminderEnabled: reminderEnabled,
  //     frequency: frequency,
  //   );

  //   await NotificationService.scheduleReminder(
  //     Reminder(
  //       id: 'habit_${habit.id}',
  //       habitId: habit.id,
  //       time: ,
  //       frequency: ReminderFrequency.daily,
  //       createdAt: habit.createdAt,
  //     ),
  //     habitName: habit.name,
  //     habitIcon: habit.icon,
  //   );

  //   _load();
  //   _push();
  // }
  Future<void> addHabit({
    required String name,
    required String icon,
    required int targetPerDay,
    required int colorIndex,
    required String reminderTime,
    required bool reminderEnabled,
    required String frequency,
  }) async {
    try {
      print('🟢 [addHabit] START');
      print('👉 name: $name');
      print('👉 reminderEnabled: $reminderEnabled');
      print('👉 reminderTime: $reminderTime');
      print('👉 frequency: $frequency');

      final habit = await _repo.addHabit(
        name: name,
        icon: icon,
        targetPerDay: targetPerDay,
        colorIndex: colorIndex,
        reminderTime: reminderTime,
        reminderEnabled: reminderEnabled,
        frequency: frequency,
      );

      print('🟡 [addHabit] HABIT SAVED: ${habit.id}');

      if (!reminderEnabled) {
        print('🔴 Reminder disabled → skipping notification');
      } else {
        final parts = reminderTime.split(':');

        if (parts.length != 2) {
          print('❌ Invalid reminderTime format: $reminderTime');
          return;
        }

        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);

        if (hour == null || minute == null) {
          print('❌ Failed to parse time: $reminderTime');
          return;
        }

        final time = TimeOfDay(hour: hour, minute: minute);

        print('🟣 Scheduling notification at $time');

        await NotificationService.scheduleReminder(
          Reminder(
            id: 'habit_${habit.id}',
            habitId: habit.id,
            time: time,
            frequency: ReminderFrequency.daily,
            createdAt: habit.createdAt,
            isEnabled: true,
          ),
          habitName: habit.name,
          habitIcon: habit.icon,
        );

        print('🟢 Notification scheduled successfully');
      }

      _load();
      _push();

      print('🟢 [addHabit] COMPLETE');
    } catch (e, stack) {
      print('🔥 ERROR in addHabit: $e');
      print(stack);
    }
  }

  Future<void> updateHabit(Habit h) async {
    await _repo.updateHabit(h);
    _load();
    _push();
  }

  Future<void> deleteHabit(String id) async {
    await _repo.deleteHabit(id);
    _load();
    _push();
  }

  void refresh() => _load();

  void _push() {
    final uid = _auth.user?.id;
    if (uid != null && _sync.isOnline) {
      unawaited(_repo.pushPending(uid, _sync));
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHECKINS
// ══════════════════════════════════════════════════════════════════════════════
final checkinProvider =
    StateNotifierProvider<CheckinNotifier, AsyncValue<List<Checkin>>>(
  (ref) => CheckinNotifier(
    ref.watch(habitRepoProvider),
    ref.watch(syncServiceProvider),
    ref.watch(authStateProvider),
  ),
);

class CheckinNotifier extends StateNotifier<AsyncValue<List<Checkin>>> {
  final HabitRepository _repo;
  final SyncService _sync;
  final AppAuthState _auth;

  CheckinNotifier(this._repo, this._sync, this._auth)
      : super(const AsyncValue.loading()) {
    _load();
  }

  void _load() => state = AsyncValue.data(_repo.getTodayCheckins());

  /// Returns true if habit just became fully complete for today.
  Future<bool> checkIn(String habitId, int targetPerDay) async {
    if (_repo.getTodayCheckins(habitId: habitId).length >= targetPerDay) {
      return false;
    }
    await _repo.checkIn(habitId);
    _load();
    final uid = _auth.user?.id;
    if (uid != null && _sync.isOnline) {
      unawaited(_repo.pushPending(uid, _sync));
    }
    return _repo.getTodayCheckins(habitId: habitId).length >= targetPerDay;
  }

  void refresh() => _load();
}

// ── Per-habit today count ─────────────────────────────────────────────────────
final todayCountProvider = Provider.family<int, String>((ref, habitId) {
  ref.watch(checkinProvider);
  return ref.watch(habitRepoProvider).getTodayCheckins(habitId: habitId).length;
});

// ── Per-habit checkins on a specific date ────────────────────────────────────
final dateCheckinsProvider =
    Provider.family<List<Checkin>, ({String habitId, String dateKey})>(
  (ref, args) {
    ref.watch(checkinProvider);
    return ref.watch(habitRepoProvider).getTodayCheckins(habitId: args.habitId);
  },
);

// ── Per-habit streak ──────────────────────────────────────────────────────────
final streakProvider = Provider.family<Streak, String>((ref, habitId) {
  ref.watch(checkinProvider);
  return ref.watch(habitRepoProvider).calculateStreak(habitId);
});

// ── Dashboard aggregates ──────────────────────────────────────────────────────
final progressProvider = Provider<({int done, int total})>((ref) {
  final habits = ref.watch(habitListProvider).value ?? [];
  ref.watch(checkinProvider);
  final repo = ref.watch(habitRepoProvider);
  final done = habits
      .where(
          (h) => repo.getTodayCheckins(habitId: h.id).length >= h.targetPerDay)
      .length;
  return (done: done, total: habits.length);
});

final overallStreakProvider = Provider<int>((ref) {
  final habits = ref.watch(habitListProvider).value ?? [];
  if (habits.isEmpty) return 0;
  ref.watch(checkinProvider);
  final repo = ref.watch(habitRepoProvider);
  return habits
      .map((h) => repo.calculateStreak(h.id).currentStreak)
      .reduce((a, b) => a > b ? a : b);
});

final longestEverProvider = Provider<int>((ref) {
  final habits = ref.watch(habitListProvider).value ?? [];
  if (habits.isEmpty) return 0;
  ref.watch(checkinProvider);
  final repo = ref.watch(habitRepoProvider);
  return habits
      .map((h) => repo.calculateStreak(h.id).longestStreak)
      .reduce((a, b) => a > b ? a : b);
});

// ══════════════════════════════════════════════════════════════════════════════
//  REMINDERS
// ══════════════════════════════════════════════════════════════════════════════
final reminderListProvider =
    StateNotifierProvider<ReminderNotifier, AsyncValue<List<Reminder>>>(
  (ref) => ReminderNotifier(ref.watch(reminderRepoProvider)),
);

class ReminderNotifier extends StateNotifier<AsyncValue<List<Reminder>>> {
  final ReminderRepository _repo;

  ReminderNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  void _load() => state = AsyncValue.data(_repo.getAll());

  Future<Reminder> add({
    required String habitId,
    required TimeOfDay time,
    required ReminderFrequency frequency,
    required List<int> customDays,
    required String message,
    required String habitName,
    required String habitIcon,
  }) async {
    final r = await _repo.add(
      habitId: habitId,
      time: time,
      frequency: frequency,
      customDays: customDays,
      message: message,
    );
    await NotificationService.scheduleReminder(r,
        habitName: habitName, habitIcon: habitIcon);
    // await NotificationService.scheduleReminder(habitName, habitIcon);
    _load();
    return r;
  }

  Future<void> toggle(String reminderId) async {
    await _repo.toggle(reminderId);
    _load();
  }

  Future<void> delete(String reminderId) async {
    await _repo.delete(reminderId);
    _load();
  }

  Future<void> deleteForHabit(String habitId) async {
    await _repo.deleteForHabit(habitId);
    _load();
  }

  Future<void> syncWithCloud(
    String userId,
    Map<String, String> habitNames,
    Map<String, String> habitIcons,
  ) async {
    await _repo.fullSync(userId, habitNames, habitIcons);
    _load();
  }

  Future<void> pushPending(String userId) async {
    await _repo.pushPending(userId);
  }

  void refresh() => _load();
}

// ── Reminders for a specific habit ───────────────────────────────────────────
final habitRemindersProvider = Provider.family<List<Reminder>, String>(
  (ref, habitId) {
    final all = ref.watch(reminderListProvider).value ?? [];
    return all.where((r) => r.habitId == habitId).toList();
  },
);

// ── Count of enabled reminders (nav badge) ────────────────────────────────────
final activeReminderCountProvider = Provider<int>((ref) {
  final all = ref.watch(reminderListProvider).value ?? [];
  return all.where((r) => r.isEnabled).length;
});

// ── OS pending notification count ─────────────────────────────────────────────
final pendingNotifCountProvider =
    FutureProvider<int>((_) => NotificationService.getPendingCount());

// ── Notification permission ───────────────────────────────────────────────────
final notificationPermissionProvider =
    StateNotifierProvider<NotifPermissionNotifier, bool>(
  (_) => NotifPermissionNotifier(),
);

class NotifPermissionNotifier extends StateNotifier<bool> {
  NotifPermissionNotifier() : super(true) {
    _check();
  }

  Future<void> _check() async {
    state = await NotificationService.requestPermission();
  }

  Future<bool> request() async {
    final granted = await NotificationService.requestPermission();
    state = granted;
    return granted;
  }

  void refresh() => _check();
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHALLENGES
// ══════════════════════════════════════════════════════════════════════════════
final challengeListProvider =
    StateNotifierProvider<ChallengeNotifier, AsyncValue<List<Challenge>>>(
  (ref) => ChallengeNotifier(ref.watch(challengeRepoProvider)),
);

class ChallengeNotifier extends StateNotifier<AsyncValue<List<Challenge>>> {
  final ChallengeRepository _repo;

  ChallengeNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  void _load() => state = AsyncValue.data(_repo.getAll());

  Future<Challenge> create({
    required String title,
    required String description,
    required String emoji,
    required List<String> habitIds,
    required int targetDays,
    required int colorIndex,
  }) async {
    final c = await _repo.create(
      title: title,
      description: description,
      emoji: emoji,
      habitIds: habitIds,
      targetDays: targetDays,
      colorIndex: colorIndex,
    );
    _load();
    return c;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }

  Future<void> markCompleted(String id) async {
    await _repo.updateStatus(id, ChallengeStatus.completed);
    _load();
  }

  Future<void> markFailed(String id) async {
    await _repo.updateStatus(id, ChallengeStatus.failed);
    _load();
  }

  /// Evaluate active challenges against current streaks.
  /// Returns challenges that changed status (for celebratory UI).
  Future<List<Challenge>> evaluate(
      Map<String, int> currentStreaksByHabit) async {
    final changed = await _repo.evaluate(currentStreaksByHabit);
    if (changed.isNotEmpty) _load();
    return changed;
  }

  Future<void> syncWithCloud(String userId) async {
    await _repo.fullSync(userId);
    _load();
  }

  Future<void> pushPending(String userId) async {
    await _repo.pushPending(userId);
  }

  void refresh() => _load();
}

// ── Active / completed / failed ───────────────────────────────────────────────
final activeChallengesProvider = Provider<List<Challenge>>((ref) {
  final all = ref.watch(challengeListProvider).value ?? [];
  return all.where((c) => c.status == ChallengeStatus.active).toList();
});

final completedChallengesProvider = Provider<List<Challenge>>((ref) {
  final all = ref.watch(challengeListProvider).value ?? [];
  return all.where((c) => c.status == ChallengeStatus.completed).toList();
});

final failedChallengesProvider = Provider<List<Challenge>>((ref) {
  final all = ref.watch(challengeListProvider).value ?? [];
  return all.where((c) => c.status == ChallengeStatus.failed).toList();
});

// ── Count for nav badge ───────────────────────────────────────────────────────
final activeChallengeCountProvider =
    Provider<int>((ref) => ref.watch(activeChallengesProvider).length);

// ── Challenges linked to a specific habit ─────────────────────────────────────
final habitChallengesProvider =
    Provider.family<List<Challenge>, String>((ref, habitId) {
  final all = ref.watch(challengeListProvider).value ?? [];
  return all
      .where((c) =>
          c.habitIds.contains(habitId) && c.status == ChallengeStatus.active)
      .toList();
});

// ══════════════════════════════════════════════════════════════════════════════
//  COMBINED SYNC ORCHESTRATOR
//  Call after login or app resume to sync reminders + challenges together.
// ══════════════════════════════════════════════════════════════════════════════
class P3SyncOrchestrator {
  final Ref _ref;
  P3SyncOrchestrator(this._ref);

  Future<void> syncAll(
    String userId, {
    required Map<String, String> habitNames,
    required Map<String, String> habitIcons,
  }) async {
    await Future.wait([
      _ref
          .read(reminderListProvider.notifier)
          .syncWithCloud(userId, habitNames, habitIcons),
      _ref.read(challengeListProvider.notifier).syncWithCloud(userId),
    ]);
  }

  Future<void> pushAllPending(String userId) async {
    await Future.wait([
      _ref.read(reminderListProvider.notifier).pushPending(userId),
      _ref.read(challengeListProvider.notifier).pushPending(userId),
    ]);
  }
}

final p3SyncProvider =
    Provider<P3SyncOrchestrator>((ref) => P3SyncOrchestrator(ref));
