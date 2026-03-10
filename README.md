# YourGPT Flutter SDK

A Flutter package for integrating YourGPT chatbot widget into Flutter applications.

## Quick Start

### Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  yourgpt_flutter_sdk: ^1.1.0
  webview_flutter: ^4.4.2
```

Then run:

```bash
flutter pub get
```

### Step 1: Update Platform Configuration

**Android** — add internet permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** — no additional permissions needed.

### Step 2: Initialize and Open the Chat Widget

```dart
import 'package:yourgpt_flutter_sdk/yourgpt_flutter_sdk.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            YourGPTChatScreen.showAsBottomSheet(
              context: context,
              widgetUid: 'your-widget-uid',
            );
          },
          child: Text('Open Chat'),
        ),
      ),
    );
  }
}
```

That's it. The SDK handles the WebView, loading states, and lifecycle internally.

### Quick Initialize (One-Liner)

For the simplest setup with notifications auto-enabled:

```dart
await YourGPTSDK.quickInitialize('your-widget-uid');
```

---

## Configuration

```dart
final config = YourGPTConfig(
  widgetUid: 'your-widget-uid',      // Required
  debug: true,                        // Optional: Enable debug logs (default: false)
  customParams: {'lang': 'en'},       // Optional: Additional widget URL query params
  enableNotifications: true,          // Optional: Enable push notifications (default: false)
  notificationMode: NotificationMode.minimalist, // Optional: .minimalist, .advanced, or .disabled
  autoRegisterToken: true,            // Optional: Auto-register FCM/APNs token (default: true)
);

await YourGPTSDK.instance.initialize(config);
```

### Push Notifications

```dart
final config = YourGPTConfig(
  widgetUid: 'your-widget-uid',
  enableNotifications: true,
  notificationConfig: YourGPTNotificationConfig(
    soundEnabled: true,
    badgeEnabled: true,
    quietHoursEnabled: true,
    quietHoursStart: 22,
    quietHoursEnd: 8,
  ),
);

await YourGPTSDK.instance.initialize(config);
```

See [NOTIFICATION_SETUP.md](NOTIFICATION_SETUP.md) for complete setup instructions.

---

## Opening the Chatbot

### Simple (uses config from `initialize()`)

```dart
YourGPTSDK.show(context);
```

### With explicit widget UID

```dart
YourGPTChatScreen.showAsBottomSheet(
  context: context,
  widgetUid: 'your-widget-uid',
);
```

### With callbacks

```dart
YourGPTChatScreen.showAsBottomSheet(
  context: context,
  widgetUid: 'your-widget-uid',
  onMessage: (message) => print('New message: $message'),
  onChatOpened: () => print('Chat opened'),
  onChatClosed: () => print('Chat closed'),
  onError: (error) => print('Error: $error'),
);
```

### Open a specific conversation

```dart
YourGPTSDK.openSession(context, sessionUid: 'conversation-uid');
```

### Create a standalone widget

Use `createChatWidget` when you want to embed the chatbot in your own navigation:

```dart
final chatWidget = YourGPTSDK.createChatWidget(
  widgetUid: 'your-widget-uid',
  controller: controller,
  eventListener: MyEventListener(),
);
```

### Embedded usage

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => Scaffold(
      body: SafeArea(
        child: YourGPTChatScreen(widgetUid: 'your-widget-uid'),
      ),
    ),
  ),
);
```

---

## Widget Data Methods

Use `YourGPTChatController` to send data to the widget after it's opened:

```dart
final controller = YourGPTChatController();

YourGPTChatScreen.showAsBottomSheet(
  context: context,
  widgetUid: 'your-widget-uid',
  controller: controller,
);

// Send session-specific data
controller.setSessionData({'orderId': '12345', 'plan': 'premium'});

// Send visitor data (auto-enriched with device info)
controller.setVisitorData({'userId': 'user_abc', 'name': 'John'});

// Send contact information
controller.setContactData({'email': 'john@example.com', 'phone': '+1234567890'});

// Send a message programmatically
controller.sendMessage('Hello!');

// Navigate to a specific conversation
controller.openSession('conversation-uid');
```

---

## Event Handling

### Global Event Listener

Implement `YourGPTEventListener` to receive SDK-wide events:

```dart
class MyEventListener extends YourGPTEventListener {
  // Required — widget events
  @override void onMessageReceived(Map<String, dynamic> message) { }
  @override void onChatOpened() { }
  @override void onChatClosed() { }
  @override void onError(String error) { }
  @override void onLoadingStarted() { }
  @override void onLoadingFinished() { }

  // Optional — message events
  @override void onMessageSent(Map<String, dynamic> message) { }

  // Optional — connection events
  @override void onConnectionEstablished() { }
  @override void onConnectionLost({String? reason}) { }
  @override void onConnectionRestored() { }

  // Optional — interaction events
  @override void onUserTyping() { }
  @override void onUserStoppedTyping() { }

  // Optional — escalation events
  @override void onEscalationToHuman() { }
  @override void onEscalationResolved() { }

  // Optional — push notification events
  @override void onPushTokenReceived(String token) { }
  @override void onPushMessageReceived(Map<String, dynamic> data) { }
  @override void onNotificationClicked(Map<String, dynamic> data) { }
  @override void onNotificationPermissionGranted() { }
  @override void onNotificationPermissionDenied() { }
}

YourGPTSDK.instance.setEventListener(MyEventListener());
```

### Per-Widget Listener

```dart
YourGPTChatScreen.showAsBottomSheet(
  context: context,
  widgetUid: 'your-widget-uid',
  eventListener: MyEventListener(),
);
```

---

## Custom Loading & Error Views

```dart
YourGPTChatScreen.showAsBottomSheet(
  context: context,
  widgetUid: 'your-widget-uid',
  customLoadingWidget: Center(child: CircularProgressIndicator()),
  customErrorWidget: (error, retry) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Failed to load: $error'),
        ElevatedButton(onPressed: retry, child: Text('Try Again')),
      ],
    ),
  ),
);
```

---

## SDK State

```dart
// Observe state changes
YourGPTSDK.instance.stateStream.listen((state) {
  switch (state.connectionState) {
    case YourGPTConnectionState.connected: print('Ready');
    case YourGPTConnectionState.connecting: print('Connecting...');
    case YourGPTConnectionState.error: print('Error: ${state.error}');
    case YourGPTConnectionState.disconnected: print('Disconnected');
  }
});

// Check readiness
if (YourGPTSDK.instance.isReady) {
  // SDK is initialized, not loading, and has no errors
}
```

---

## Error Handling

```dart
try {
  await YourGPTSDK.instance.initialize(config);
} on InvalidConfigurationError catch (e) {
  // Invalid or missing widget UID
} on NotInitializedError {
  // SDK not initialized
} on NotReadyError {
  // SDK still loading
} on YourGPTError catch (e) {
  // Other SDK errors
}
```

| Error Type                  | Description                                         |
| --------------------------- | --------------------------------------------------- |
| `InvalidConfigurationError` | Configuration is invalid or missing required fields |
| `NotInitializedError`       | SDK has not been initialized                        |
| `NotReadyError`             | SDK is not ready (still loading or in error state)  |
| `InvalidURLError`           | Failed to build a valid widget URL                  |
| `WebViewLoadError`          | An error occurred in the WebView                    |

---

## Requirements

- Flutter 3.13 or newer
- Dart 3.0 or newer
- Android: minSdk 21+, compileSdk 33+
- iOS: 12.0+

## Support

- Documentation: [https://docs.yourgpt.ai](https://docs.yourgpt.ai)
- Issues: [GitHub Issues](https://github.com/YourGPT/yourgpt-widget-sdk-flutter/issues)
- Email: support@yourgpt.ai
