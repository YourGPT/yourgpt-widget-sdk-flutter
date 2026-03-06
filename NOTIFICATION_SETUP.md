# YourGPT Flutter SDK - Push Notification Setup

This guide explains how to enable push notifications in your Flutter app using the YourGPT SDK. When set up, your users will receive notifications for new messages from the YourGPT widget even when the app is in the background or closed.

## Features

- **Background Notifications**: Receive messages when the app is closed or in the background
- **Automatic Token Management**: FCM/APNs token is fetched, cached, and registered with the backend automatically
- **Two Modes**: Minimalist (auto-handles everything) or Advanced (custom handling)
- **Cross-Platform**: Single codebase handles both Android (FCM) and iOS (APNs)

## Prerequisites

1. Flutter >= 3.13 / Dart >= 3.0
2. A YourGPT account with a **widget UID**
3. A Firebase project with Android and/or iOS apps registered
4. For iOS: An Apple Developer account with push notification entitlements and a physical device

---

## Step 1: Firebase Project Setup

### 1.1 Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 1.2 Configure Firebase

```bash
flutterfire configure
```

This generates:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

---

## Step 2: Android Setup

### 2.1 Add the Google Services plugin

**`android/build.gradle`**:
```groovy
classpath 'com.google.gms:google-services:4.4.0'
```

**`android/app/build.gradle`**:
```groovy
apply plugin: 'com.google.gms.google-services'
```

### 2.2 Permissions

`android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

---

## Step 3: iOS Setup

1. In Xcode: **Runner → Signing & Capabilities → + Capability → Push Notifications**
2. Add **Background Modes** and enable **Remote notifications**
3. Create an APNs key at [Apple Developer → Keys](https://developer.apple.com/account/resources/authkeys/list)
4. Download the `.p8` file, note the **Key ID** and **Team ID**

---

## Step 4: Configure Push Notifications on YourGPT Dashboard

### For Android (FCM)

1. **Firebase Console** → **Project Settings** → **Service Accounts** → **Generate new private key**
2. **YourGPT Dashboard** → chatbot **Settings** → **Notifications** → Enable **FCM** → Upload the JSON file

### For iOS (APNs)

1. **YourGPT Dashboard** → chatbot **Settings** → **Notifications** → Enable **APNs**
2. Enter **Team ID**, **Key ID**, **Bundle ID**, and upload the `.p8` file

Once status shows **"Configured"**, your backend is ready to send push notifications.

---

## Step 5: Flutter Integration

### Option A: Quick Setup (Recommended)

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:yourgpt_flutter_sdk/yourgpt_flutter_sdk.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(yourgptFirebaseBackgroundHandler);

  // One-liner: initializes SDK + notifications
  await YourGPTSDK.quickInitialize('YOUR_WIDGET_UID');

  // Handle notification taps
  YourGPTNotificationClient.instance.setWidgetOpenCallback((sessionUid) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null && sessionUid != null) {
      YourGPTSDK.openSession(ctx, sessionUid: sessionUid);
    } else if (ctx != null) {
      YourGPTSDK.show(ctx);
    }
  });

  runApp(MyApp());
}
```

### Option B: Full Configuration

```dart
await YourGPTNotificationClient.instance.initialize(
  widgetUid: 'YOUR_WIDGET_UID',
  mode: NotificationMode.minimalist,
  config: YourGPTNotificationConfig(
    quietHoursEnabled: true,
    quietHoursStart: 22,
    quietHoursEnd: 8,
  ),
);
```

---

## Step 6: Open the Widget at Least Once

The push token is registered with the YourGPT backend **through the WebView JS bridge** when the widget is opened. Until the widget is opened at least once, the backend won't know where to send notifications.

```dart
YourGPTSDK.show(context);
```

---

## How It Works

```
1. App starts → Firebase initialized → FCM/APNs token fetched and cached locally
2. User opens widget → Token sent to YourGPT backend via WebView JS bridge
3. New message on backend → FCM (Android) or APNs (iOS) push sent to device
4. YourGPTNotificationClient handles message → Notification displayed
5. User taps notification → Widget opens via widgetOpenCallback
```

---

## Notification Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `minimalist` | Auto-handles everything: display, grouping, tap actions | Most apps — zero custom code needed |
| `advanced` | SDK identifies YourGPT notifications but does not display them | Apps that need custom notification UI |
| `disabled` | No notification handling | Apps that don't want push notifications |

```dart
// Set during initialization
NotificationMode.minimalist  // or .advanced, .disabled

// Or change at runtime
YourGPTNotificationClient.instance.setNotificationMode(NotificationMode.advanced);
```

---

## Notification Configuration

```dart
YourGPTNotificationConfig(
  // Master switch
  notificationsEnabled: true,

  // Sound
  soundEnabled: true,
  soundName: null,                  // null = system default

  // iOS badge
  badgeEnabled: true,

  // Android vibration
  vibrationEnabled: true,
  vibrationPattern: [0, 300, 200, 300],

  // Grouping
  groupMessages: true,
  threadIdentifierPrefix: 'com.yourgpt.sdk',
  groupKey: 'com.yourgpt.sdk.MESSAGES',   // Android group key

  // Auto-dismiss
  autoDismissOnOpen: true,

  // Quiet hours
  quietHoursEnabled: true,
  quietHoursStart: 22,
  quietHoursEnd: 8,

  // Message preview
  showMessagePreview: true,
  maxPreviewLength: 100,

  // Reply & stacking
  showReplyAction: true,
  stackNotifications: true,
  maxNotificationStack: 5,

  // Android channel
  channelId: 'yourgpt_messages',
  channelName: 'YourGPT Messages',
  channelDescription: 'Chat messages from YourGPT AI assistant',

  // Android LED & priority
  ledEnabled: true,
  ledColor: 0xFF0000FF,
  ledOnMs: 300,
  ledOffMs: 3000,
  priority: 1,
  autoCancel: true,
  smallIconRes: '@mipmap/ic_launcher',

  // iOS category
  categoryIdentifier: 'chat_message',
)
```

### Available Options

| Option | Default | Description |
|--------|---------|-------------|
| `notificationsEnabled` | `true` | Master switch for notifications |
| `soundEnabled` | `true` | Play sound on notification |
| `soundName` | `null` (system) | Custom sound file name |
| `badgeEnabled` | `true` | Update app badge count (iOS) |
| `vibrationEnabled` | `true` | Vibrate on notification (Android) |
| `vibrationPattern` | `null` (system) | Custom vibration pattern in ms |
| `groupMessages` | `true` | Group notifications by conversation |
| `threadIdentifierPrefix` | `com.yourgpt.sdk` | Thread identifier prefix |
| `groupKey` | `com.yourgpt.sdk.MESSAGES` | Android notification group key |
| `autoDismissOnOpen` | `true` | Remove notifications when widget opens |
| `quietHoursEnabled` | `false` | Suppress notifications during hours |
| `quietHoursStart` / `End` | `22` / `8` | Quiet hours range (24h format) |
| `showMessagePreview` | `true` | Show message content in notification |
| `maxPreviewLength` | `100` | Max characters in preview |
| `showReplyAction` | `true` | Show inline reply action |
| `stackNotifications` | `true` | Stack multiple notifications |
| `maxNotificationStack` | `5` | Max before removing oldest |
| `channelId` | `yourgpt_messages` | Android notification channel ID |
| `channelName` | `YourGPT Messages` | Android notification channel name |
| `channelDescription` | `Chat messages from...` | Android notification channel description |
| `ledEnabled` | `true` | LED indicator (Android) |
| `ledColor` | `0xFF0000FF` | LED color as ARGB (Android) |
| `ledOnMs` / `ledOffMs` | `300` / `3000` | LED timing in ms (Android) |
| `priority` | `1` (high) | Notification priority (Android) |
| `autoCancel` | `true` | Dismiss on tap (Android) |
| `smallIconRes` | `@mipmap/ic_launcher` | Small icon resource (Android) |
| `categoryIdentifier` | `chat_message` | UNNotification category (iOS) |

---

## Rich Notifications

### Action Notification

```dart
await YourGPTNotificationHelper.showActionNotification(
  title: 'New Message',
  body: 'You have a new message',
  actions: [
    NotificationAction(identifier: 'reply', title: 'Reply'),
    NotificationAction(identifier: 'dismiss', title: 'Dismiss', foreground: false),
  ],
  data: {'widget_uid': 'your-uid'},
  config: YourGPTNotificationConfig(),
);
```

### Rich Notification (with subtitle)

```dart
await YourGPTNotificationHelper.showRichNotification(
  title: 'Support Agent',
  body: 'How can I help?',
  subtitle: 'Order #12345',
  data: data,
  config: notifConfig,
);
```

### Extract Reply Text

```dart
// In notification response handler:
final replyText = YourGPTNotificationHelper.getReplyText(response);
```

---

## SDK Methods Reference

### Notification Detection & Handling

```dart
// Check if a payload is from YourGPT
final isYourGPT = YourGPTNotificationClient.instance.isYourGPTNotification(data);

// Handle incoming notification (returns true if handled)
final handled = YourGPTNotificationClient.instance.handleNotification(data);

// Handle notification tap (returns true if handled)
final tapped = YourGPTNotificationClient.instance.handleNotificationClick(data);

// Manually notify SDK of push received (advanced mode)
YourGPTNotificationClient.instance.notifyPushReceived(data);
YourGPTSDK.notifyPushReceived(data);  // or from main SDK
```

### Token Management

```dart
// Get cached token
final token = YourGPTNotificationClient.instance.cachedToken;

// Get fresh FCM token
final freshToken = await YourGPTNotificationHelper.getToken();

// Reset token (on user logout)
await YourGPTNotificationClient.instance.resetToken();

// Request permission and register in one call
final granted = await YourGPTNotificationClient.instance.requestPermissionAndRegister();
```

### Widget

```dart
// Open widget from notification client
YourGPTNotificationClient.instance.openWidget(context, sessionUid: 'conversation-uid');

// Or use the SDK facade
YourGPTSDK.show(context);
YourGPTSDK.openSession(context, sessionUid: 'conversation-uid');
```

### State & Mode

```dart
final ready = YourGPTNotificationClient.instance.isInitialized;
final mode = YourGPTNotificationClient.instance.currentMode;
final config = YourGPTNotificationClient.instance.currentNotificationConfig;

YourGPTNotificationClient.instance.setNotificationMode(NotificationMode.advanced);
```

### Notification Utilities

```dart
final enabled = await YourGPTNotificationHelper.areNotificationsEnabled();
final granted = await YourGPTNotificationHelper.requestPermission();

await YourGPTNotificationHelper.removeAllDeliveredNotifications();
await YourGPTNotificationHelper.removeNotification(notificationId);

// Badge management (iOS)
await YourGPTNotificationHelper.resetBadgeCount();
await YourGPTNotificationHelper.incrementBadgeCount();

// Register notification categories (iOS — call once at startup)
await YourGPTNotificationHelper.registerNotificationCategories();

// Generate notification ID from session UID
final id = YourGPTNotificationHelper.generateNotificationId('session-uid');
```

---

## Advanced Mode: Custom Notification Handling

If you use `NotificationMode.advanced`, the SDK identifies YourGPT notifications but does **not** display them — your app handles display.

```dart
await YourGPTNotificationClient.instance.initialize(
  widgetUid: 'YOUR_WIDGET_UID',
  mode: NotificationMode.advanced,
);

YourGPTNotificationClient.instance.setTokenCallback((token) {
  print('New push token: $token');
});

YourGPTNotificationClient.instance.setMessageCallback((data) {
  if (YourGPTNotificationClient.instance.isYourGPTNotification(data)) {
    // Show your own custom notification
  }
});
```

---

## Complete Example

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:yourgpt_flutter_sdk/yourgpt_flutter_sdk.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(yourgptFirebaseBackgroundHandler);

  await YourGPTSDK.quickInitialize('YOUR_WIDGET_UID');

  YourGPTNotificationClient.instance.setWidgetOpenCallback((sessionUid) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null && sessionUid != null) {
      YourGPTSDK.openSession(ctx, sessionUid: sessionUid);
    } else if (ctx != null) {
      YourGPTSDK.show(ctx);
    }
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My App')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => YourGPTSDK.show(context),
          child: Text('Open Chat'),
        ),
      ),
    );
  }
}
```

---

## Testing

1. Install on a **physical device** (FCM may not work on emulators; push does not work on iOS Simulator)
2. Grant notification permission when prompted
3. Open the widget at least once (so the push token is registered with the backend)
4. Close the app
5. Send a test message through the YourGPT dashboard

---

## Troubleshooting

### Notifications not received

1. Verify credentials show **"Configured"** on the YourGPT Dashboard
2. **Android**: Verify `google-services.json` is in `android/app/`
3. **iOS**: Confirm Push Notifications and Background Modes capabilities in Xcode
4. Ensure the widget was opened at least once after SDK initialization
5. Enable `debug: true` and check console for `[YourGPT]` logs

### Notifications received but not displayed

1. **Android**: Ensure `POST_NOTIFICATIONS` permission is granted (Android 13+)
2. Check that the notification channel is not disabled in device settings
3. Verify `notificationMode` is not `.disabled`
4. Check that quiet hours are not active

### Widget doesn't open on notification tap

1. Verify `setWidgetOpenCallback` is called during app initialization
2. Ensure the `navigatorKey` is passed to your `MaterialApp`

### Token not registered

1. The push token is sent via the WebView JS bridge — the widget must be opened at least once
2. Check console for `"Token registered via WebView"` message

## Support

For issues or questions, please refer to the main [README](README.md) or contact YourGPT support.
