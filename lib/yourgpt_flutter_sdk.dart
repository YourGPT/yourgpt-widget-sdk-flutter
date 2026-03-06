/// YourGPT Flutter SDK
///
/// Import this single file to access the entire SDK public API:
///
/// ```dart
/// import 'package:yourgpt_flutter_sdk/yourgpt_flutter_sdk.dart';
/// ```
library yourgpt_flutter_sdk;

// Core SDK
export 'yourgpt_sdk.dart';

// Configuration
export 'config.dart'
    show
        YourGPTConfig,
        YourGPTSDKConfig,
        YourGPTConfigBuilder,
        NotificationMode,
        createConfig;

// Chat UI
export 'yourgpt_chat_screen.dart';

// Controller
export 'yourgpt_chat_controller.dart';

// Event listener interface
export 'yourgpt_event_listener.dart';

// Error types
export 'yourgpt_error.dart';

// Push notifications
export 'yourgpt_notification_config.dart';
export 'yourgpt_notification_client.dart'
    show YourGPTNotificationClient, yourgptFirebaseBackgroundHandler;
export 'yourgpt_notification_helper.dart';

// Native APNs channel (iOS)
export 'yourgpt_apns_channel.dart';