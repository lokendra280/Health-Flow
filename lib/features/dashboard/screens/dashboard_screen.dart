import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitflow/core/constants/app_string.dart';
import 'package:habitflow/core/constants/constant_assets.dart';
import 'package:habitflow/core/constants/size_constant.dart';
import 'package:habitflow/core/providers/date_provider.dart';
import 'package:habitflow/features/ai_plan/providers/ai_plan_provider.dart';
import 'package:habitflow/features/ai_plan/providers/weekly_workout_provider.dart';
import 'package:habitflow/features/dashboard/screens/widgets/feedback_promot.dart';
import 'package:habitflow/features/dashboard/screens/widgets/feedback_sheet.dart';
import 'package:habitflow/features/dashboard/screens/widgets/greeting_header.dart';
import 'package:habitflow/features/dashboard/screens/widgets/log_weight_sheet.dart';
import 'package:habitflow/features/dashboard/screens/widgets/personal_workout_card.dart';
import 'package:habitflow/features/dashboard/screens/widgets/quick_actions_grid.dart';
import 'package:habitflow/features/dashboard/screens/widgets/today_calendar_strip.dart';
import 'package:habitflow/features/dashboard/screens/widgets/weekly_goals_row.dart';
import 'package:habitflow/features/steps/ui/step_count_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_common.dart';
import '../../../data/models/dashboard_data.dart';
import '../../../data/models/dashboard_ui_models.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  List<ProgressMetric> metrics(DashboardData data, int realSteps) {
    final waterCurrent = (data.waterProgress * data.waterTarget).round();
    final stepsProgress = (realSteps / data.stepTarget).clamp(0.0, 1.0);
    return [
      ProgressMetric(
        label: 'Calories',
        valueLabel: '${(data.calorieProgress * 100).round()}% of daily goal',
        progress: data.calorieProgress,
        icon: Icons.local_fire_department,
        color: AppColors.calories,
        background: AppColors.caloriesBg,
      ),
      ProgressMetric(
        label: 'Water',
        valueLabel: '$waterCurrent / ${data.waterTarget} ml',
        progress: data.waterProgress,
        icon: Icons.water_drop,
        color: AppColors.water,
        background: AppColors.waterBg,
      ),
      ProgressMetric(
        label: 'Steps',
        valueLabel: '$realSteps / ${data.stepTarget} steps',
        progress: stepsProgress,
        icon: Icons.directions_walk,
        color: AppColors.steps,
        background: AppColors.stepsBg,
      ),
      ProgressMetric(
        label: 'Sleep',
        valueLabel: '${(data.sleepProgress * 100).round()}% of 8h goal',
        progress: data.sleepProgress,
        icon: Icons.bedtime,
        color: AppColors.sleep,
        background: AppColors.sleepBg,
      ),
    ];
  }

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (FeedbackPromptService.shouldShowToday) {
          showFeedbackSheet(context, isDailyPrompt: true);
        }
      });
    });
  }

  Widget build(BuildContext context) {
    final data = ref.watch(dashboardDataProvider);
    final realSteps = ref.watch(todayStepsProvider).valueOrNull ?? 0;
    final metrics = widget.metrics(data, realSteps);

    final sections = <Widget>[
      GreetingHeader(
        userName: '',
        notificationCount: 0,
        onNotificationsTap: () {
          showFeedbackSheet(context, isDailyPrompt: true);
        },
      ),
      const SizedBox(height: 20),
      const WeeklyGoalsRow(),
      SBC.lHM,
      TodayCalendarStrip(
        selectedDate: ref.watch(dashboardSelectedDateProvider),
        onDateSelected: (DateTime value) {
          ref.read(dashboardSelectedDateProvider.notifier).state = value;
        },
      ),
      SBC.lHM,

      Consumer(
        builder: (context, ref, _) {
          final summary = ref.watch(todayWorkoutSummaryProvider);
          final plan = ref.watch(aiPlanControllerProvider);
          final selectedDate = ref.watch(dashboardSelectedDateProvider);
          final todayWorkout = plan?.workoutForWeekday(selectedDate);
          final isRestDay = todayWorkout?.isRestDay ?? true;
          final isToday = selectedDate.day == DateTime.now().day;

          String title = "Today's Workout";
          if (isRestDay) {
            title = isToday ? "Today is Rest Day" : "Rest Day";
          } else if (!isToday) {
            title = "Workout for ${selectedDate.day}/${selectedDate.month}";
          }

          return PersonalWorkoutCard(
            title: title,
            completedCount: summary.completedCount,
            totalCount: summary.totalCount,
            onTap: () {
              context.push('/daily-workout');
            },
          );
        },
      ),

      SBC.lH,

      // AiInsightCard(onTap: () => context.push('/weekly-review')),
      SBC.lH,
      Text(
        'Quick actions',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      SBC.lHM,
      QuickActionsGrid(
        actions: [
          QuickAction(
              icon: Assets.bed,
              label: 'Add weight',
              onTap: () => showLogWeightSheet(context, ref)),
          QuickAction(
            icon: Assets.camera,
            label: AppString.trackCalories,
            onTap: () => context.push('/food'),
          ),

          QuickAction(
            icon: Assets.sleep,
            label: 'Sleep Track',
            onTap: () => context.push('/sleep'),
          ),
          // QuickAction(
          //   icon: Icons.boy_rounded,
          //   label: 'Body Progress',
          //   onTap: () => context.push('/body-progress'),
          // ),
          QuickAction(
              icon: Assets.water,
              label: AppString.trackWater,
              onTap: () => context.push('/water')),
          // QuickAction(
          //     icon: Icons.directions_run,
          //     label: 'Add workout',
          //     onTap: () => context.push('/activity')),
          QuickAction(
              icon: Assets.habit,
              label: 'Habits',
              onTap: () => context.push('/habits')),
          // QuickAction(
          //     icon: Assets.checkIn,
          //     label: 'Daily CheckIn',
          //     onTap: () => context.push('/check-in')),
          // QuickAction(
          //     icon: Icons.chat_bubble,
          //     label: 'Ask AI',
          //     onTap: () => context.push('/ai-coach')),
          // QuickAction(
          //   icon: Icons.emoji_events,
          //   label: 'Milestones',
          //   onTap: () => context.push('/milestones'),
          // ),
          // QuickAction(
          //   icon: Assets.report,
          //   label: "Journey Completion",
          //   onTap: () => context.push('/journey-completion'),
          // ),
          QuickAction(
            icon: Assets.running,
            label: AppString.stepCounter,
            onTap: () => context.push('step-counter'),
          ),
          // QuickAction(
          //   icon: Assets.report,
          //   label: 'Report',
          //   onTap: () => context.push('/reports'),
          // ),
        ],
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          children: [
            for (var i = 0; i < sections.length; i++)
              StaggerFadeIn(index: i, child: sections[i]),
          ],
        ),
      ),
    );
  }
}
