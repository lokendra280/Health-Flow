import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  /// Checks for update and performs immediate update if available.
  static Future<void> checkForUpdate() async {
    // In-app updates only work on Android.
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint('In-app update check failed: $e');
    }
  }
}
