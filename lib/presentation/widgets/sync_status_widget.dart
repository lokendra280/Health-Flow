import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SYNC STATUS WIDGET
//  compact: true  → small pill/icon for app bar
//  compact: false → full card with details + sync button
// ─────────────────────────────────────────────────────────────────────────────
class SyncStatusWidget extends ConsumerWidget {
  final bool compact;
  const SyncStatusWidget({super.key, this.compact = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStateProvider);

    return compact
        ? _CompactBadge(sync: sync, ref: ref)
        : _FullCard(sync: sync, ref: ref);
  }
}

// ─── Compact Badge ────────────────────────────────────────────────────────────
class _CompactBadge extends StatelessWidget {
  final SyncState sync;
  final WidgetRef ref;
  const _CompactBadge({required this.sync, required this.ref});

  @override
  Widget build(BuildContext ctx) {
    final cfg = _config(ctx, sync.status);
    return GestureDetector(
      onTap: () => ref.read(syncStateProvider.notifier).syncNow(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cfg.bg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: cfg.border, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sync.isSyncing)
              SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: cfg.fg,
                ),
              )
            else
              Icon(cfg.icon, size: 13, color: cfg.fg),
            const Gap(5),
            Text(
              cfg.label,
              style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: cfg.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Full Card ────────────────────────────────────────────────────────────────
class _FullCard extends StatelessWidget {
  final SyncState sync;
  final WidgetRef ref;
  const _FullCard({required this.sync, required this.ref});

  @override
  Widget build(BuildContext ctx) {
    final cfg = _config(ctx, sync.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ctx.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ctx.borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: cfg.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: sync.isSyncing
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: cfg.fg,
                        ),
                      )
                    : Icon(cfg.icon, size: 20, color: cfg.fg),
              ),
            ),
            const Gap(14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cfg.title,
                    style: ctx.syne(15, FontWeight.w700)),
                Text(
                  sync.message ?? cfg.subtitle,
                  style: ctx.dmSans(12, FontWeight.w400,
                      color: ctx.textSecondary),
                ),
              ],
            )),
            // Sync now button
            if (!sync.isSyncing)
              GestureDetector(
                onTap: () => ref.read(syncStateProvider.notifier).syncNow(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: ctx.accentSurf,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('Sync Now',
                      style: ctx.dmSans(12, FontWeight.w600,
                          color: ctx.accent)),
                ),
              ),
          ]),

          if (sync.lastSynced != null) ...[
            const Gap(14),
            Divider(color: ctx.borderColor),
            const Gap(10),
            Row(children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 15, color: ctx.accent),
              const Gap(6),
              Text(
                'Last synced ${_timeAgo(sync.lastSynced!)}',
                style: ctx.dmSans(12, FontWeight.w400,
                    color: ctx.textTertiary),
              ),
            ]),
          ],

          // Offline indicator
          if (sync.isOffline) ...[
            const Gap(14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber100.withOpacity(
                    ctx.isDark ? 0.12 : 1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.amber700.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 18, color: AppColors.amber700),
                const Gap(10),
                Expanded(child: Text(
                  'You\'re offline. Changes are saved locally and '
                  'will sync when you reconnect.',
                  style: ctx.dmSans(12, FontWeight.w400,
                      color: AppColors.amber700),
                )),
              ]),
            ),
          ],

          // Unsynced count
          const _UnsyncedCount(),
        ],
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60)  return 'just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(t);
  }
}

// ─── Unsynced Count ───────────────────────────────────────────────────────────
class _UnsyncedCount extends ConsumerWidget {
  const _UnsyncedCount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits   = ref.watch(habitListProvider).value ?? [];
    final checkins = ref.watch(checkinProvider).value ?? [];
    final unSynced = habits.where((h) => !h.isSynced).length
                   + checkins.where((c) => !c.isSynced).length;

    if (unSynced == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.cloud_upload_outlined,
              size: 16, color: context.accent),
          const Gap(8),
          Text(
            '$unSynced item${unSynced > 1 ? "s" : ""} waiting to sync',
            style: context.dmSans(12, FontWeight.w500,
                color: context.textSecondary),
          ),
        ]),
      ),
    );
  }
}

// ─── Config helper ────────────────────────────────────────────────────────────
class _Cfg {
  final Color  fg, bg, border;
  final IconData icon;
  final String label, title, subtitle;
  const _Cfg({
    required this.fg, required this.bg, required this.border,
    required this.icon, required this.label,
    required this.title, required this.subtitle,
  });
}

_Cfg _config(BuildContext ctx, SyncStatus status) {
  switch (status) {
    case SyncStatus.syncing:
      return _Cfg(
        fg: ctx.accent, bg: ctx.accentSurf,
        border: ctx.accent.withOpacity(0.3),
        icon: Icons.sync_rounded,
        label: 'Syncing…',
        title: 'Syncing…',
        subtitle: 'Uploading your latest changes',
      );
    case SyncStatus.success:
      return _Cfg(
        fg: ctx.accent, bg: ctx.accentSurf,
        border: ctx.accent.withOpacity(0.3),
        icon: Icons.cloud_done_rounded,
        label: 'Synced',
        title: 'Up to date',
        subtitle: 'All changes synced to cloud',
      );
    case SyncStatus.error:
      return _Cfg(
        fg: AppColors.coral700,
        bg: AppColors.coral100.withOpacity(ctx.isDark ? 0.12 : 1),
        border: AppColors.coral700.withOpacity(0.3),
        icon: Icons.cloud_off_rounded,
        label: 'Error',
        title: 'Sync failed',
        subtitle: 'Tap to retry',
      );
    case SyncStatus.offline:
      return _Cfg(
        fg: AppColors.amber700,
        bg: AppColors.amber100.withOpacity(ctx.isDark ? 0.12 : 1),
        border: AppColors.amber700.withOpacity(0.3),
        icon: Icons.wifi_off_rounded,
        label: 'Offline',
        title: 'Offline mode',
        subtitle: 'Changes saved locally',
      );
    case SyncStatus.idle:
      return _Cfg(
        fg: ctx.textTertiary, bg: ctx.surface2,
        border: ctx.borderColor,
        icon: Icons.cloud_outlined,
        label: 'Cloud',
        title: 'Cloud Sync',
        subtitle: 'Tap to sync your habits',
      );
  }
}
