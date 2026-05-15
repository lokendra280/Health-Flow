import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─── AppUser ──────────────────────────────────────────────────────────────────
class AppUser {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.createdAt,
    this.username,
    this.avatarUrl,
  });

  AppUser copyWith(
          {String? id,
          String? email,
          String? username,
          String? avatarUrl,
          DateTime? createdAt}) =>
      AppUser(
          id: id ?? this.id,
          email: email ?? this.email,
          username: username ?? this.username,
          avatarUrl: avatarUrl ?? this.avatarUrl,
          createdAt: createdAt ?? this.createdAt);

  String get displayName =>
      (username?.isNotEmpty == true) ? username! : email.split('@').first;

  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName
        .substring(0, displayName.length.clamp(1, 2))
        .toUpperCase();
  }
}

// ─── Auth Status ────────────────────────────────────────────────────────────────
enum AuthStatus { loading, authenticated, unauthenticated }

// ─── SyncState ────────────────────────────────────────────────────────────────
enum SyncStatus { idle, syncing, success, error, offline }

class SyncState {
  final SyncStatus status;
  final String? message;
  final DateTime? lastSynced;

  const SyncState({required this.status, this.message, this.lastSynced});
  const SyncState.idle()
      : status = SyncStatus.idle,
        message = null,
        lastSynced = null;

  bool get isSyncing => status == SyncStatus.syncing;
  bool get isOffline => status == SyncStatus.offline;
  bool get hasError => status == SyncStatus.error;
}

// ─── Habit ────────────────────────────────────────────────────────────────────
class Habit {
  final String id;
  final String name;
  final String icon;
  final int targetPerDay;
  final DateTime createdAt;
  final bool isActive;
  final int colorIndex;
  final bool isSynced;
  final DateTime? updatedAt;

  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetPerDay,
    required this.createdAt,
    required this.colorIndex,
    this.isActive = true,
    this.isSynced = false,
    this.updatedAt,
  });

  Color get color =>
      AppColors.habitPalette[colorIndex % AppColors.habitPalette.length];

  Habit copyWith(
          {String? id,
          String? name,
          String? icon,
          int? targetPerDay,
          DateTime? createdAt,
          bool? isActive,
          int? colorIndex,
          bool? isSynced,
          DateTime? updatedAt}) =>
      Habit(
          id: id ?? this.id,
          name: name ?? this.name,
          icon: icon ?? this.icon,
          targetPerDay: targetPerDay ?? this.targetPerDay,
          createdAt: createdAt ?? this.createdAt,
          isActive: isActive ?? this.isActive,
          colorIndex: colorIndex ?? this.colorIndex,
          isSynced: isSynced ?? this.isSynced,
          updatedAt: updatedAt ?? this.updatedAt);

  Map<String, dynamic> toSupabase(String userId) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'icon': icon,
        'target_per_day': targetPerDay,
        'color_index': colorIndex,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory Habit.fromSupabase(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String,
        icon: j['icon'] as String,
        targetPerDay: j['target_per_day'] as int,
        createdAt: DateTime.parse(j['created_at'] as String),
        colorIndex: j['color_index'] as int,
        isActive: j['is_active'] as bool,
        isSynced: true,
        updatedAt: j['updated_at'] != null
            ? DateTime.parse(j['updated_at'] as String)
            : null,
      );
}

// ─── Checkin ─────────────────────────────────────────────────────────────────
class Checkin {
  final String id;
  final String habitId;
  final DateTime timestamp;
  final bool isSynced;

  const Checkin(
      {required this.id,
      required this.habitId,
      required this.timestamp,
      this.isSynced = false});

  String get dateKey {
    final d = timestamp;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toSupabase(String userId) => {
        'id': id,
        'user_id': userId,
        'habit_id': habitId,
        'checked_at': timestamp.toIso8601String(),
        'date_key': dateKey,
      };

  factory Checkin.fromSupabase(Map<String, dynamic> j) => Checkin(
        id: j['id'] as String,
        habitId: j['habit_id'] as String,
        timestamp: DateTime.parse(j['checked_at'] as String),
        isSynced: true,
      );
}

// ─── Streak ──────────────────────────────────────────────────────────────────
class Streak {
  final String habitId;
  final int currentStreak;
  final int longestStreak;
  final int totalCheckins;
  final DateTime? lastCheckinDate;

  const Streak(
      {required this.habitId,
      required this.currentStreak,
      required this.longestStreak,
      this.totalCheckins = 0,
      this.lastCheckinDate});
}

// ─── DayStat ──────────────────────────────────────────────────────────────────
class DayStat {
  final DateTime date;
  final int done;
  final int total;
  double get rate => total == 0 ? 0 : done / total;
  const DayStat({required this.date, required this.done, required this.total});
}

// ─── Reminder ─────────────────────────────────────────────────────────────────
enum ReminderFrequency { once, daily, weekdays, weekends, custom }

class Reminder {
  final String id;
  final String habitId;
  final TimeOfDay time;
  final ReminderFrequency frequency;
  final List<int> customDays; // 1=Mon .. 7=Sun
  final bool isEnabled;
  final String message;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Reminder({
    required this.id,
    required this.habitId,
    required this.time,
    required this.frequency,
    required this.createdAt,
    this.customDays = const [],
    this.isEnabled = true,
    this.message = '',
    this.isSynced = false,
    this.updatedAt,
  });

  String get frequencyLabel {
    switch (frequency) {
      case ReminderFrequency.once:
        return 'Once';
      case ReminderFrequency.daily:
        return 'Every day';
      case ReminderFrequency.weekdays:
        return 'Weekdays';
      case ReminderFrequency.weekends:
        return 'Weekends';
      case ReminderFrequency.custom:
        if (customDays.isEmpty) return 'Custom';
        const n = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return customDays.map((d) => n[d]).join(', ');
    }
  }

  Reminder copyWith({
    String? id,
    String? habitId,
    TimeOfDay? time,
    ReminderFrequency? frequency,
    List<int>? customDays,
    bool? isEnabled,
    String? message,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Reminder(
        id: id ?? this.id,
        habitId: habitId ?? this.habitId,
        time: time ?? this.time,
        frequency: frequency ?? this.frequency,
        customDays: customDays ?? this.customDays,
        isEnabled: isEnabled ?? this.isEnabled,
        message: message ?? this.message,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toSupabase(String userId) => {
        'id': id,
        'user_id': userId,
        'habit_id': habitId,
        'time_hour': time.hour,
        'time_minute': time.minute,
        'frequency_index': frequency.index,
        'custom_days': customDays,
        'is_enabled': isEnabled,
        'message': message,
        'updated_at': DateTime.now().toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Reminder.fromSupabase(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        habitId: j['habit_id'] as String,
        time: TimeOfDay(
          hour: j['time_hour'] as int,
          minute: j['time_minute'] as int,
        ),
        frequency: ReminderFrequency.values[j['frequency_index'] as int],
        customDays: List<int>.from(j['custom_days'] as List? ?? []),
        isEnabled: j['is_enabled'] as bool,
        message: j['message'] as String? ?? '',
        isSynced: true,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: j['updated_at'] != null
            ? DateTime.parse(j['updated_at'] as String)
            : null,
      );
}

// ─── Challenge ────────────────────────────────────────────────────────────────
enum ChallengeStatus { active, completed, failed }

class Challenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final List<String> habitIds;
  final int targetDays;
  final DateTime startDate;
  final DateTime? completedDate;
  final ChallengeStatus status;
  final int colorIndex;
  final bool isSynced;
  final DateTime? updatedAt;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.habitIds,
    required this.targetDays,
    required this.startDate,
    required this.colorIndex,
    this.completedDate,
    this.status = ChallengeStatus.active,
    this.isSynced = false,
    this.updatedAt,
  });

  Color get color =>
      AppColors.habitPalette[colorIndex % AppColors.habitPalette.length];

  int daysElapsed() => DateTime.now().difference(startDate).inDays + 1;
  int daysRemaining() => (targetDays - daysElapsed()).clamp(0, targetDays);
  double progressPct() => (daysElapsed() / targetDays).clamp(0.0, 1.0);

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    List<String>? habitIds,
    int? targetDays,
    DateTime? startDate,
    DateTime? completedDate,
    ChallengeStatus? status,
    int? colorIndex,
    bool? isSynced,
    DateTime? updatedAt,
  }) =>
      Challenge(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        emoji: emoji ?? this.emoji,
        habitIds: habitIds ?? this.habitIds,
        targetDays: targetDays ?? this.targetDays,
        startDate: startDate ?? this.startDate,
        completedDate: completedDate ?? this.completedDate,
        status: status ?? this.status,
        colorIndex: colorIndex ?? this.colorIndex,
        isSynced: isSynced ?? this.isSynced,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toSupabase(String userId) => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'emoji': emoji,
        'habit_ids': habitIds,
        'target_days': targetDays,
        'start_date': startDate.toIso8601String(),
        'completed_date': completedDate?.toIso8601String(),
        'status_index': status.index,
        'color_index': colorIndex,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory Challenge.fromSupabase(Map<String, dynamic> j) => Challenge(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        emoji: j['emoji'] as String,
        habitIds: List<String>.from(j['habit_ids'] as List? ?? []),
        targetDays: j['target_days'] as int,
        startDate: DateTime.parse(j['start_date'] as String),
        completedDate: j['completed_date'] != null
            ? DateTime.parse(j['completed_date'] as String)
            : null,
        status: ChallengeStatus.values[j['status_index'] as int],
        colorIndex: j['color_index'] as int,
        isSynced: true,
        updatedAt: j['updated_at'] != null
            ? DateTime.parse(j['updated_at'] as String)
            : null,
      );

  /// Preset challenge templates
  static const List<Map<String, dynamic>> templates = [
    {
      'title': '7-Day Kickstart',
      'emoji': '🚀',
      'description': 'Build momentum with 7 consecutive days.',
      'targetDays': 7
    },
    {
      'title': '21-Day Habit Lock',
      'emoji': '🔒',
      'description': 'Science says 21 days forms a habit.',
      'targetDays': 21
    },
    {
      'title': '30-Day Challenge',
      'emoji': '🏆',
      'description': 'A full month of consistency.',
      'targetDays': 30
    },
    {
      'title': '66-Day Master',
      'emoji': '👑',
      'description': 'The real habit formation window.',
      'targetDays': 66
    },
    {
      'title': '100-Day Hero',
      'emoji': '🦸',
      'description': 'Elite-level dedication.',
      'targetDays': 100
    },
  ];
}
