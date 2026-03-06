import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'config.dart';
import 'yourgpt_apns_channel.dart';
import 'yourgpt_event_listener.dart';
import 'yourgpt_notification_helper.dart';

// ---------------------------------------------------------------------------
// Background message handler (Android only)
//
// This MUST be a top-level function (not a class method) and be annotated
// with @pragma('vm:entry-point') so the Dart AOT compiler keeps it.
//
// Register it in your app's main() BEFORE runApp() (Android only):
//
//   void main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//     if (defaultTargetPlatform == TargetPlatform.android) {
//       await Firebase.initializeApp();
//       FirebaseMessaging.onBackgroundMessage(yourgptFirebaseBackgroundHandler);
//     }
//     runApp(MyApp());
//   }
// ---------------------------------------------------------------------------

/// Top-level Firebase background message handler for YourGPT (Android only).
///
/// Pass this to [FirebaseMessaging.onBackgroundMessage] in your app's [main].
/// Not needed on iOS — APNs handles background delivery natively.
@pragma('vm:entry-point')
Future<void> yourgptFirebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('[YourGPT] Background message received: ${message.messageId}');
  debugPrint('[YourGPT]   bg data: ${message.data}');

  // Data-only messages won't auto-display — show a local notification manually.
  final data = message.data;
  final hasWidgetUid = data.containsKey('widget_uid') || data.containsKey('project_uid');
  if (!hasWidgetUid) {
    debugPrint('[YourGPT]   bg SKIPPED — not a YourGPT notification');
    return;
  }

  final title = message.notification?.title
      ?? data['title'] as String?
      ?? 'New Message';
  final body = message.notification?.body
      ?? data['body'] as String?
      ?? '';

  // Initialize the local notification plugin (background isolate has no prior state).
  await YourGPTNotificationHelper.initialize();

  await YourGPTNotificationHelper.showLocalNotification(
    title: title,
    body: body,
    data: data,
    config: const YourGPTNotificationConfig(),
    sessionUid: data['session_uid'] as String?,
  );
  debugPrint('[YourGPT]   bg notification displayed: "$title" / "$body"');
}

// ---------------------------------------------------------------------------
// YourGPTNotificationClient
// ---------------------------------------------------------------------------

/// Manages push notification token registration, foreground display, and
/// notification tap handling for the YourGPT SDK.
///
/// Platform behaviour:
/// - **iOS**: Uses native APNs via MethodChannel ([YourGPTApnsChannel]).
///   Sends `register_push_token` to the widget.
/// - **Android**: Uses Firebase Cloud Messaging ([FirebaseMessaging]).
///   Sends `register_fcm_token` to the widget.
///
/// ## Quick setup (most apps)
/// ```dart
/// await YourGPTNotificationClient.instance.quickSetup('your-widget-uid');
/// ```
///
/// ## Full setup
/// ```dart
/// await YourGPTNotificationClient.instance.initialize(
///   widgetUid: 'your-widget-uid',
///   mode: NotificationMode.minimalist,
///   config: YourGPTNotificationConfig(quietHoursEnabled: true),
/// );
/// ```
class YourGPTNotificationClient {
  static final YourGPTNotificationClient instance =
      YourGPTNotificationClient._();
  YourGPTNotificationClient._();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  String? _widgetUid;
  NotificationMode _mode = NotificationMode.minimalist;
  YourGPTNotificationConfig _config = const YourGPTNotificationConfig();
  String? _cachedToken;
  YourGPTEventListener? _eventListener;

  // Android-only (Firebase)
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _tapSubscription;

  // Queued notification tap from cold start (listener not yet set).
  Map<String, dynamic>? _pendingNotificationTap;

  // Callbacks for advanced mode
  void Function(String token)? _tokenCallback;
  void Function(Map<String, dynamic> data)? _messageCallback;
  void Function(String? sessionUid)? _widgetOpenCallback;

  static const String _tokenPrefKey = 'yourgpt_sdk_push_token';

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  /// Whether [initialize] or [quickSetup] has been called.
  bool get isInitialized => _widgetUid != null;

  /// The most recently received and cached push token (APNs on iOS, FCM on Android).
  String? get cachedToken => _cachedToken;

  /// The active notification handling mode.
  NotificationMode get currentMode => _mode;

  /// The active notification configuration.
  YourGPTNotificationConfig get currentNotificationConfig => _config;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Full initialisation with explicit configuration.
  ///
  /// On iOS, this sets up native APNs via [YourGPTApnsChannel].
  /// On Android, this sets up Firebase Cloud Messaging.
  Future<void> initialize({
    required String widgetUid,
    NotificationMode mode = NotificationMode.minimalist,
    YourGPTNotificationConfig? config,
  }) async {
    _widgetUid = widgetUid;
    _mode = mode;
    _config = config ?? const YourGPTNotificationConfig();

    debugPrint('[YourGPT] initialize: widgetUid=$widgetUid, mode=$mode, platform=${_isIOS ? "iOS" : "Android"}');

    if (mode == NotificationMode.disabled) {
      debugPrint('[YourGPT] initialize: notifications DISABLED, skipping setup');
      return;
    }

    // Load previously cached token from persistent storage.
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenPrefKey);
    debugPrint('[YourGPT] initialize: cached token from prefs = ${_cachedToken != null ? '${_cachedToken!.substring(0, 10)}...' : 'NULL'}');

    if (_isIOS) {
      await _initializeIOS();
    } else {
      await _initializeAndroid();
    }
  }

  /// iOS initialisation — native APNs via MethodChannel.
  Future<void> _initializeIOS() async {
    YourGPTApnsChannel.startListening();

    // Listen for APNs token delivery / refresh.
    YourGPTApnsChannel.setTokenCallback((token) async {
      await _persistToken(token);
      _eventListener?.onPushTokenReceived(token);
      _tokenCallback?.call(token);
      debugPrint('[YourGPTNotificationClient] APNs token received: $token');
    });

    YourGPTApnsChannel.setTokenErrorCallback((error) {
      debugPrint('[YourGPTNotificationClient] APNs token error: $error');
      _eventListener?.onError(error);
    });

    // Notification tap handling.
    YourGPTApnsChannel.setNotificationTapCallback((data) {
      if (!isYourGPTNotification(data)) return;
      _eventListener?.onNotificationClicked(data);
      final sessionUid = data['session_uid'] as String?;
      _widgetOpenCallback?.call(sessionUid);
    });

    // Foreground notification received.
    YourGPTApnsChannel.setNotificationReceivedCallback((data) {
      if (!isYourGPTNotification(data)) return;
      _eventListener?.onPushMessageReceived(data);
      _messageCallback?.call(data);
    });

    // Permission callbacks.
    YourGPTApnsChannel.setPermissionGrantedCallback(() {
      _eventListener?.onNotificationPermissionGranted();
    });
    YourGPTApnsChannel.setPermissionDeniedCallback(() {
      _eventListener?.onNotificationPermissionDenied();
    });

    // Request permission (triggers registerForRemoteNotifications on grant).
    if (_mode == NotificationMode.minimalist) {
      await YourGPTApnsChannel.requestPermission();
    }

    // Try to get an already-cached token from the native side.
    final token = await YourGPTApnsChannel.getToken();
    if (token != null && token.isNotEmpty) {
      await _persistToken(token);
      _eventListener?.onPushTokenReceived(token);
      _tokenCallback?.call(token);
    }
  }

  /// Android initialisation — Firebase Cloud Messaging.
  Future<void> _initializeAndroid() async {
    debugPrint('[YourGPT] _initializeAndroid: starting FCM setup...');

    // Initialize local notification plugin for displaying foreground notifications.
    await YourGPTNotificationHelper.initialize(
      onNotificationTap: (data) {
        debugPrint('[YourGPT] Local notification tapped: $data');
        if (!isYourGPTNotification(data)) return;

        if (_eventListener == null) {
          debugPrint('[YourGPT] Local notification tap queued (listener not set yet)');
          _pendingNotificationTap = Map<String, dynamic>.from(data);
          return;
        }

        debugPrint('[YourGPT] Local notification tap firing onNotificationClicked');
        _eventListener?.onNotificationClicked(data);
        final sessionUid = data['session_uid'] as String?;
        _widgetOpenCallback?.call(sessionUid);
      },
    );
    debugPrint('[YourGPT] _initializeAndroid: local notifications initialized');

    // Register background handler.
    FirebaseMessaging.onBackgroundMessage(yourgptFirebaseBackgroundHandler);
    debugPrint('[YourGPT] _initializeAndroid: background handler registered');

    // Foreground messages.
    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen(_handleIncomingMessage);
    debugPrint('[YourGPT] _initializeAndroid: foreground listener attached');

    // Background → foreground tap (app was in background, notification tapped).
    _tapSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Token refresh.
    _tokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint('[YourGPT] FCM token REFRESHED: $token');
      _onTokenRefreshed(token);
    });

    // Request notification permission (required on Android 13+ / API 33+).
    if (_mode == NotificationMode.minimalist) {
      final granted = await YourGPTNotificationHelper.requestPermission();
      debugPrint('[YourGPT] _initializeAndroid: permission granted = $granted');
      if (granted) {
        _eventListener?.onNotificationPermissionGranted();
      } else {
        _eventListener?.onNotificationPermissionDenied();
      }
    }

    // Fetch current FCM token.
    debugPrint('[YourGPT] _initializeAndroid: requesting FCM token...');
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      debugPrint('[YourGPT] FCM token received: $token');
      await _persistToken(token);
      _eventListener?.onPushTokenReceived(token);
      _tokenCallback?.call(token);
    } else {
      debugPrint('[YourGPT] FCM token is NULL — check Firebase config');
    }

    // Handle cold-start notification tap (app was terminated, notification tapped).
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[YourGPT] Cold-start notification tap detected');
      _handleNotificationTap(initialMessage);
    }

    debugPrint('[YourGPT] _initializeAndroid: FCM setup complete');
  }

  /// Convenience one-liner initialisation with default settings.
  Future<void> quickSetup(String widgetUid) async {
    await initialize(
      widgetUid: widgetUid,
      mode: NotificationMode.minimalist,
    );
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  Future<void> _onTokenRefreshed(String token) async {
    await _persistToken(token);
    _eventListener?.onPushTokenReceived(token);
    _tokenCallback?.call(token);
  }

  Future<void> _persistToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefKey, token);
    debugPrint('[YourGPT] Token persisted to SharedPreferences (${token.substring(0, 10)}...)');
  }

  /// Sends the cached token to the YourGPT backend via the WebView JS bridge.
  ///
  /// Called automatically by [YourGPTChatScreen] when the WebView finishes
  /// loading, if [YourGPTConfig.autoRegisterToken] is `true`.
  ///
  /// On iOS, sends `register_push_token` with the native APNs token.
  /// On Android, sends `register_fcm_token` with the FCM token.
  Future<void> registerTokenViaWebView(WebViewController webView) async {
    debugPrint('[YourGPT] registerTokenViaWebView called — cachedToken: ${_cachedToken != null ? '${_cachedToken!.substring(0, 10)}...' : 'NULL'}, widgetUid: $_widgetUid');
    if (_cachedToken == null || _widgetUid == null) {
      debugPrint('[YourGPT] registerTokenViaWebView SKIPPED — token or widgetUid is null');
      return;
    }

    final platform = _isIOS ? 'ios' : 'android';
    final messageType = _isIOS ? 'register_push_token' : 'register_fcm_token';

    final payload = jsonEncode({
      'token': _cachedToken,
      'platform': platform,
      'widget_uid': _widgetUid,
    });

    await webView.runJavaScript('''
      window.postMessage({
        type: '$messageType',
        payload: $payload
      }, '*');
    ''');

    debugPrint(
      '[YourGPTNotificationClient] Token registered via WebView '
      '(type: $messageType, platform: $platform).',
    );
  }

  // ---------------------------------------------------------------------------
  // Notification detection
  // ---------------------------------------------------------------------------

  /// Returns `true` if [data] belongs to a YourGPT notification.
  ///
  /// Use this in [NotificationMode.advanced] to identify SDK messages before
  /// applying your own display logic.
  bool isYourGPTNotification(Map<String, dynamic> data) {
    return data.containsKey('widget_uid') || data.containsKey('project_uid');
  }

  // ---------------------------------------------------------------------------
  // Message handling (Android — Firebase)
  // ---------------------------------------------------------------------------

  void _handleIncomingMessage(RemoteMessage message) {
    debugPrint('[YourGPT] FCM foreground message received — messageId: ${message.messageId}');
    debugPrint('[YourGPT]   data keys: ${message.data.keys.toList()}');
    debugPrint('[YourGPT]   data: ${message.data}');
    debugPrint('[YourGPT]   notification: ${message.notification?.title} / ${message.notification?.body}');

    if (!isYourGPTNotification(message.data)) {
      debugPrint('[YourGPT]   SKIPPED — not a YourGPT notification (missing widget_uid/project_uid in data)');
      return;
    }

    debugPrint('[YourGPT]   Identified as YourGPT notification, mode=$_mode');
    _eventListener?.onPushMessageReceived(message.data);
    _messageCallback?.call(message.data);

    if (_mode == NotificationMode.minimalist) {
      // Use notification payload if present, otherwise fall back to data fields.
      final title = message.notification?.title
          ?? message.data['title'] as String?
          ?? 'New Message';
      final body = message.notification?.body
          ?? message.data['body'] as String?
          ?? '';

      debugPrint('[YourGPT]   Showing local notification: "$title" / "$body"');
      YourGPTNotificationHelper.showLocalNotification(
        title: title,
        body: body,
        data: message.data,
        config: _config,
        sessionUid: message.data['session_uid'] as String?,
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (!isYourGPTNotification(message.data)) return;

    if (_eventListener == null) {
      // Cold start — listener not wired yet. Queue for replay.
      debugPrint('[YourGPT] Notification tap queued (listener not set yet)');
      _pendingNotificationTap = Map<String, dynamic>.from(message.data);
      return;
    }

    debugPrint('[YourGPT] Notification tap firing onNotificationClicked');
    _eventListener?.onNotificationClicked(message.data);

    final sessionUid = message.data['session_uid'] as String?;
    _widgetOpenCallback?.call(sessionUid);
  }

  // ---------------------------------------------------------------------------
  // Callbacks (advanced mode)
  // ---------------------------------------------------------------------------

  /// Sets the global event listener (mirrors [YourGPTSDK.setEventListener]).
  void setEventListener(YourGPTEventListener? listener) {
    _eventListener = listener;

    // Replay any notification tap that arrived before the listener was set
    // (cold start: app killed → notification tap → app launches → listener wired).
    // Deferred to after the first frame so the widget tree (Navigator, etc.) is ready.
    if (listener != null && _pendingNotificationTap != null) {
      final data = _pendingNotificationTap!;
      _pendingNotificationTap = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[YourGPT] Replaying queued notification tap: $data');
        listener.onNotificationClicked(data);
        final sessionUid = data['session_uid'] as String?;
        _widgetOpenCallback?.call(sessionUid);
      });
    }
  }

  /// Called when a notification tap should open the chat widget.
  ///
  /// Provide a callback that presents [YourGPTChatScreen] (or calls
  /// [YourGPTChatScreen.openSession]) with the given [sessionUid].
  void setWidgetOpenCallback(void Function(String? sessionUid) callback) {
    _widgetOpenCallback = callback;
  }

  /// [NotificationMode.advanced] only — called when a push token is received.
  void setTokenCallback(void Function(String token) callback) {
    _tokenCallback = callback;
  }

  /// [NotificationMode.advanced] only — called when a push message arrives.
  void setMessageCallback(
      void Function(Map<String, dynamic> data) callback) {
    _messageCallback = callback;
  }

  /// Changes the active notification mode at runtime.
  void setNotificationMode(NotificationMode mode) {
    _mode = mode;
  }

  // ---------------------------------------------------------------------------
  // Notification handling (parity with Android / iOS SDKs)
  // ---------------------------------------------------------------------------

  /// Processes an incoming push notification payload.
  ///
  /// Returns `true` if [data] is a YourGPT notification and was handled,
  /// `false` otherwise.
  ///
  /// In [NotificationMode.minimalist] mode this also displays a local
  /// notification automatically.
  ///
  /// Mirrors `handleNotification` on Android and iOS SDKs.
  bool handleNotification(Map<String, dynamic> data) {
    if (!isYourGPTNotification(data)) return false;

    _eventListener?.onPushMessageReceived(data);
    _messageCallback?.call(data);

    if (_mode == NotificationMode.minimalist) {
      final title = data['title'] as String? ?? 'New Message';
      final body = data['body'] as String? ?? '';

      YourGPTNotificationHelper.showLocalNotification(
        title: title,
        body: body,
        data: data,
        config: _config,
        sessionUid: data['session_uid'] as String?,
      );
    }

    return true;
  }

  /// Handles a notification tap / click.
  ///
  /// Returns `true` if [data] is a YourGPT notification and the tap was
  /// processed, `false` otherwise.
  ///
  /// Mirrors `handleNotificationClick` (Android) and
  /// `handleNotificationResponse` (iOS).
  bool handleNotificationClick(Map<String, dynamic> data) {
    if (!isYourGPTNotification(data)) return false;

    _eventListener?.onNotificationClicked(data);

    final sessionUid = data['session_uid'] as String?;
    _widgetOpenCallback?.call(sessionUid);

    return true;
  }

  /// Manually notifies the SDK that a push notification was received.
  ///
  /// Use this in [NotificationMode.advanced] when your app handles
  /// notification display itself but still wants the SDK to track the event.
  ///
  /// Mirrors `notifyPushReceived` on Android and iOS SDKs.
  void notifyPushReceived(Map<String, dynamic> data) {
    if (!isYourGPTNotification(data)) return;
    _eventListener?.onPushMessageReceived(data);
    _messageCallback?.call(data);
  }

  /// Opens the chat widget, optionally navigating to a specific session.
  ///
  /// Requires a [BuildContext] to present the widget. If [sessionUid] is
  /// provided, the widget opens directly to that conversation.
  ///
  /// Mirrors `openWidget` on Android and iOS SDKs.
  void openWidget(BuildContext context, {String? sessionUid}) {
    if (_widgetUid == null) return;

    if (sessionUid != null) {
      _widgetOpenCallback?.call(sessionUid);
    } else {
      _widgetOpenCallback?.call(null);
    }
  }

  /// Notifies the SDK of the result of a notification permission request.
  ///
  /// Call this after requesting notification permission to inform the SDK
  /// and fire the appropriate event listener callback.
  ///
  /// Mirrors `onPermissionResult` on the Android SDK.
  void onPermissionResult(bool granted) {
    if (granted) {
      _eventListener?.onNotificationPermissionGranted();
    } else {
      _eventListener?.onNotificationPermissionDenied();
    }
  }

  /// Requests notification permission and registers for push notifications
  /// in a single call.
  ///
  /// Returns `true` if permission was granted.
  ///
  /// Mirrors `requestPermissionAndRegister` on the iOS SDK.
  Future<bool> requestPermissionAndRegister() async {
    final granted = await YourGPTNotificationHelper.requestPermission();
    onPermissionResult(granted);

    if (granted) {
      final token = await YourGPTNotificationHelper.getToken();
      if (token != null) {
        await _persistToken(token);
        _eventListener?.onPushTokenReceived(token);
        _tokenCallback?.call(token);
      }
    }

    return granted;
  }

  // ---------------------------------------------------------------------------
  // Token reset
  // ---------------------------------------------------------------------------

  /// Clears the cached push token.
  ///
  /// Call this when the user logs out so that subsequent push notifications
  /// are not delivered to this device.
  Future<void> resetToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefKey);
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _tapSubscription?.cancel();
    _widgetUid = null;
  }
}
