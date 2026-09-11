import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/date_utils.dart';

/// Provides the current local date (normalized to midnight).
/// Automatically refreshes itself at every local midnight.
class CurrentDateNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    _scheduleMidnightRefresh();
    return DateTime.now().normalized;
  }

  void refresh() {
    final newDate = DateTime.now().normalized;
    if (state != newDate) {
      state = newDate;
      _scheduleMidnightRefresh();
    }
  }

  void _scheduleMidnightRefresh() {
    _timer?.cancel();
    
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    // Schedule a refresh at exactly midnight + a tiny buffer
    _timer = Timer(timeUntilMidnight + const Duration(seconds: 1), () {
      state = DateTime.now().normalized;
      _scheduleMidnightRefresh(); // Schedule for the next midnight
    });
  }
}

final currentDateProvider = NotifierProvider<CurrentDateNotifier, DateTime>(
  CurrentDateNotifier.new,
);
