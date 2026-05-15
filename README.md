# 🌿 HabitFlow — Phase 2

> **Builds on Phase 1.** Copy Phase 2 files into your existing project, or run standalone.

---

## ✨ What's New in Phase 2

### 🔔 Reminders & Notifications
- **`NotificationService`** — schedules exact-time local push notifications via `flutter_local_notifications`
- **5 frequency modes** — Once / Daily / Weekdays / Weekends / Custom (day picker)
- **Per-habit reminders** — each habit can have multiple reminders
- **Toggle on/off** without deleting
- **Test notification** fires immediately after setting to confirm it works
- Notifications survive device reboot (Android boot receiver registered)

### 📊 Insights & Analytics (3 tabs)
| Tab | Content |
|---|---|
| **Overview** | KPI chips (avg rate, perfect days, total done), animated bar chart, line trend chart |
| **Habits** | Horizontal bar chart per habit, all-time checkin pie chart, streak breakdown |
| **Heatmap** | 13-week GitHub-style activity calendar with color intensity |

All charts built with **fl_chart** — fully themed for dark/light mode.

### 🏆 Challenges & Goals
- **5 preset templates** — 7d / 21d / 30d / 66d / 100d with emoji and description
- **Custom challenge builder** — pick emoji, title, description, days (slider + quick-picks), habits
- **Progress card** per active challenge — gradient banner, fill bar, days remaining
- **Auto-evaluate** — marks completed/failed based on streak vs target
- **Won / Active / Failed** stat pills at top

### 🌙 Advanced Animations
| Widget | Animation |
|---|---|
| `AnimatedHabitCard` | Entry slide-up + fade, checkin bounce (spring TweenSequence), icon idle pulse, shimmer sweep on completion, celebration stamp, mini particle burst |
| `AnimatedProgressCard` | Ring chart with animated arc, counter tween, fade-in |
| `AdvancedConfetti` | Physics-based multi-shape (circle, rect, triangle, ⭐ star) with wobble, gravity, per-particle opacity |

---

## 🗂 New Files (Phase 2 only)

```
lib/
├── core/
│   └── utils/
│       └── notification_service.dart     ← Full notification scheduling
│
├── data/
│   ├── models/
│   │   ├── reminder_model.dart + .g.dart ← Hive typeId 2
│   │   └── challenge_model.dart + .g.dart← Hive typeId 3
│   └── repositories/
│       ├── reminder_repository.dart
│       └── challenge_repository.dart
│
├── domain/entities/entities.dart         ← + Reminder, Challenge, DayStat
│
├── presentation/
│   ├── providers/
│   │   └── p2_providers.dart             ← Reminder + Challenge notifiers
│   ├── screens/
│   │   ├── reminders_screen.dart         ← Full reminders UI
│   │   ├── insights_screen.dart          ← 3-tab analytics
│   │   └── challenges_screen.dart        ← Challenges + templates
│   └── widgets/
│       ├── animated_habit_card.dart      ← Spring + shimmer + particles
│       ├── animated_progress_card.dart   ← Ring chart progress
│       ├── advanced_confetti.dart        ← Physics multi-shape confetti
│       └── phase2_shell.dart             ← 5-tab bottom nav shell
│
└── main.dart                             ← Full Phase 2 entry point
```

---

## 🚀 Setup

### 1. Install dependencies
```bash
flutter pub get
```

### 2. iOS — add to `ios/Runner/Info.plist`
```xml
<key>NSUserNotificationUsageDescription</key>
<string>HabitFlow uses notifications to remind you to check in.</string>
```

### 3. Run
```bash
flutter run
```

### 4. (Optional) Regenerate Hive adapters
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 📦 New Dependencies

| Package | Purpose |
|---|---|
| `flutter_local_notifications: ^17.0.0` | Push notifications |
| `timezone: ^0.9.2` | TZ-aware scheduling |
| `permission_handler: ^11.1.0` | Runtime permission requests |
| `fl_chart: ^0.68.0` | Bar, line, pie charts |
| `shared_preferences: ^2.2.2` | Light preference storage |

---

## 🔔 Notification Notes

- **Android 13+** — `POST_NOTIFICATIONS` permission requested at runtime
- **Android 12+** — `SCHEDULE_EXACT_ALARM` in manifest (included)
- **iOS** — permission dialog shown on first reminder creation
- **Notification IDs** — stable hash from reminder UUID × 10 + day index (avoids collisions)
- **Boot persistence** — Android boot receiver re-registers scheduled alarms after restart

---

## 🏗 Architecture

```
Phase2Shell
├── _HomeTab         ← AnimatedProgressCard + AnimatedHabitCard list
├── InsightsScreen   ← fl_chart tabs
├── ChallengesScreen ← templates + active + completed
├── RemindersScreen  ← per-habit grouped list + AddReminderSheet
└── _SettingsTab     ← feature list + habit overview
```

State flow:
```
RootController (StatefulWidget, owns HabitRepository calls)
    ↓ props
Phase2Shell
    ↓ Consumer reads
p2_providers (Riverpod) → ReminderRepository / ChallengeRepository
```

Phase 1 habit/checkin/streak state stays in `_RootController` (plain Dart,
directly calls `HabitRepository`). Phase 2 reminder/challenge state lives in
Riverpod providers for reactive UI updates.
