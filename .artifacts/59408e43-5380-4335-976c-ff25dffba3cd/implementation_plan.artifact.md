# Push Notifications Setup Plan

This plan outlines the steps to integrate Firebase Cloud Messaging (FCM) for push notifications in the Health-Flow (FitAura) app.

## User Review Required

> [!IMPORTANT]
> This plan assumes you have already created a Firebase project.
> For iOS, you MUST have an Apple Developer account to configure APNs (Apple Push Notification service) and enable "Push Notifications" in Xcode.

## Open Questions

1. Do you want to store FCM tokens in your Supabase database to send targeted notifications?
2. Have you already run the `flutterfire configure` command? (Since `firebase_options.dart` is missing, I assume not).

## Proposed Changes

### Dependencies

#### [MODIFY] [pubspec.yaml](file:///Users/lokendra/Downloads/Health-Flow/pubspec.yaml)
Add `firebase_core` and `firebase_messaging`.

---

### Android Configuration

#### [MODIFY] [build.gradle.kts](file:///Users/lokendra/Downloads/Health-Flow/android/build.gradle.kts)
Add Google Services classpath.

#### [MODIFY] [app/build.gradle.kts](file:///Users/lokendra/Downloads/Health-Flow/android/app/build.gradle.kts)
Apply the Google Services plugin.

#### [MODIFY] [AndroidManifest.xml](file:///Users/lokendra/Downloads/Health-Flow/android/app/src/main/AndroidManifest.xml)
Add intent-filter for handling notification clicks in the background.

---

### Push Notification Logic

#### [NEW] [push_notification_service.dart](file:///Users/lokendra/Downloads/Health-Flow/lib/core/services/push_notification_service.dart)
Create a service to handle FCM initialization, token retrieval, and message listeners.

#### [MODIFY] [main.dart](file:///Users/lokendra/Downloads/Health-Flow/lib/main.dart)
Initialize Firebase and the Push Notification Service.

---

## Verification Plan

### Automated Tests
- Not applicable for push notifications as they require a physical device or emulator with Google Play Services.

### Manual Verification
1. Run the app on an Android device/emulator with Google Play Services.
2. Check the console for the FCM token.
3. Use the Firebase Console to send a test message using the token.
4. Verify the notification is received in foreground, background, and terminated states.
