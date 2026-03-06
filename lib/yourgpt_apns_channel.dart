import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart wrapper around the native iOS APNs MethodChannel.
///
/// Provides native APNs token acquisition and notification handling on iOS.
/// On non-iOS platforms, all methods are no-ops that return safe defaults.
///
/// This class communicates with [YourGPTFlutterPlugin] (Swift) via
/// the `com.yourgpt.sdk/apns` MethodChannel.
class YourGPTApnsChannel {
  static const MethodChannel _channel = MethodChannel('com.yourgpt.sdk/apns');

  static void Function(String token)? _tokenCallback;
  static void Function(String error)? _tokenErrorCallback;
  static void Function(Map<String, dynamic> data)? _notificationTapCallback;
  static void Function(Map<String, dynamic> data)? _notificationReceivedCallback;
  static void Function()? _permissionGrantedCallback;
  static void Function()? _permissionDeniedCallback;

  static bool _isListening = false;

  /// Start listening for native callbacks from the Swift plugin.
  ///
  /// Must be called once before any other methods. Safe to call multiple times.
  static void startListening() {
    if (_isListening) return;
    _isListening = true;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onTokenReceived':
          final token = call.arguments as String?;
          if (token != null) {
            _tokenCallback?.call(token);
          }
          break;
        case 'onTokenError':
          final error = call.arguments as String? ?? 'Unknown error';
          _tokenErrorCallback?.call(error);
          break;
        case 'onNotificationTapped':
          final data = _castMap(call.arguments);
          if (data != null) {
            _notificationTapCallback?.call(data);
          }
          break;
        case 'onNotificationReceived':
          final data = _castMap(call.arguments);
          if (data != null) {
            _notificationReceivedCallback?.call(data);
          }
          break;
        case 'onPermissionGranted':
          _permissionGrantedCallback?.call();
          break;
        case 'onPermissionDenied':
          _permissionDeniedCallback?.call();
          break;
      }
    });
  }

  /// Request notification permission from the user.
  ///
  /// On iOS, this shows the system permission dialog and calls
  /// `registerForRemoteNotifications()` if granted.
  /// Returns `true` if permission was granted.
  static Future<bool> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermission');
      return granted ?? false;
    } on PlatformException catch (e) {
      debugPrint('[YourGPTApnsChannel] requestPermission failed: $e');
      return false;
    }
  }

  /// Get the cached APNs device token.
  ///
  /// Returns `null` if no token is available yet (permission not granted,
  /// or APNs hasn't delivered the token yet).
  static Future<String?> getToken() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    try {
      return await _channel.invokeMethod<String>('getToken');
    } on PlatformException catch (e) {
      debugPrint('[YourGPTApnsChannel] getToken failed: $e');
      return null;
    }
  }

  /// Check if notification permission is currently granted.
  static Future<bool> isPermissionGranted() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    try {
      final granted =
          await _channel.invokeMethod<bool>('isPermissionGranted');
      return granted ?? false;
    } on PlatformException catch (e) {
      debugPrint('[YourGPTApnsChannel] isPermissionGranted failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Callbacks
  // ---------------------------------------------------------------------------

  /// Called when an APNs device token is received or refreshed.
  static void setTokenCallback(void Function(String token) callback) {
    _tokenCallback = callback;
  }

  /// Called when APNs token registration fails.
  static void setTokenErrorCallback(void Function(String error) callback) {
    _tokenErrorCallback = callback;
  }

  /// Called when the user taps a push notification.
  static void setNotificationTapCallback(
      void Function(Map<String, dynamic> data) callback) {
    _notificationTapCallback = callback;
  }

  /// Called when a push notification is received while the app is in foreground.
  static void setNotificationReceivedCallback(
      void Function(Map<String, dynamic> data) callback) {
    _notificationReceivedCallback = callback;
  }

  /// Called when notification permission is granted.
  static void setPermissionGrantedCallback(void Function() callback) {
    _permissionGrantedCallback = callback;
  }

  /// Called when notification permission is denied.
  static void setPermissionDeniedCallback(void Function() callback) {
    _permissionDeniedCallback = callback;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Map<String, dynamic>? _castMap(dynamic arguments) {
    if (arguments is Map) {
      return arguments.cast<String, dynamic>();
    }
    return null;
  }
}
