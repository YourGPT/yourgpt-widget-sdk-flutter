/// YourGPT SDK Configuration
///
/// This file contains all configuration constants and classes used across
/// the Flutter SDK. DO NOT change [_Endpoints.widgetBase] without coordinating
/// with the backend team.
library yourgpt_config;

import 'yourgpt_notification_config.dart';

// Re-export so consumers can import everything from this single file.
export 'yourgpt_notification_config.dart';

// ---------------------------------------------------------------------------
// SDK-internal constants
// ---------------------------------------------------------------------------

/// Top-level SDK configuration constants (endpoints, metadata, defaults).
class YourGPTSDKConfig {
  /// Widget API endpoint configuration.
  static const endpoints = _Endpoints._();

  /// SDK metadata (version, platform name).
  static const sdk = _SDK._();

  /// Default configuration values.
  static const defaults = _Defaults._();
}

class _Endpoints {
  const _Endpoints._();

  /// Base widget URL — DO NOT CHANGE without backend coordination.
  static const String widgetBase = 'https://widget.yourgpt.ai';

  /// Constructs the full widget URL for [widgetUid].
  ///
  /// Format: `https://widget.yourgpt.ai/{widgetUid}`
  String widgetURL(String widgetUid) => '$widgetBase/$widgetUid';

  /// Constructs the widget URL with the given query [params].
  Uri widgetURLWithParams(String widgetUid, Map<String, String> params) {
    return Uri.parse(widgetURL(widgetUid)).replace(queryParameters: params);
  }
}

class _SDK {
  const _SDK._();

  static const String version = '1.1.0';
  static const String platform = 'Flutter';
  static const String name = 'YourGPT Flutter SDK';
}

class _Defaults {
  const _Defaults._();

  static const bool debug = false;
  static const Duration timeout = Duration(seconds: 30);
}

// ---------------------------------------------------------------------------
// Notification mode
// ---------------------------------------------------------------------------

/// Controls how the SDK handles incoming push notifications.
///
/// Mirrors [NotificationMode] from Android and iOS SDKs.
enum NotificationMode {
  /// The SDK automatically displays notifications and handles user taps.
  /// This is the recommended mode for most applications.
  minimalist,

  /// The SDK identifies YourGPT notifications but leaves display and tap
  /// handling to your application code. Use this when you need full control
  /// over the notification UI.
  advanced,

  /// Push notifications are completely disabled. The FCM token is still
  /// registered so the backend can store it for future use.
  disabled,
}

// ---------------------------------------------------------------------------
// YourGPTConfig
// ---------------------------------------------------------------------------

/// Immutable configuration object for initialising the YourGPT SDK.
///
/// Required:
/// - [widgetUid] — unique identifier for your widget (from the YourGPT dashboard).
///
/// Optional:
/// - [debug]              — enable verbose SDK logging (default `false`).
/// - [customParams]       — additional query parameters appended to the widget URL.
/// - [enableNotifications]— enable push notification support (default `false`).
/// - [notificationMode]   — how notifications are handled (default [NotificationMode.minimalist]).
/// - [autoRegisterToken]  — automatically register the FCM token when the WebView loads.
/// - [notificationConfig] — fine-grained notification appearance/behaviour settings.
class YourGPTConfig {
  /// Unique widget identifier from the YourGPT dashboard.
  final String widgetUid;

  /// Enable verbose SDK logging to the debug console.
  final bool debug;

  /// Additional query parameters to append to the widget URL.
  ///
  /// These are merged with the SDK's own parameters (sdk, sdkVersion,
  /// mobileWebView). Custom params take precedence on key conflicts.
  final Map<String, String> customParams;

  /// Whether to enable push notification support.
  final bool enableNotifications;

  /// How push notifications are handled when [enableNotifications] is `true`.
  final NotificationMode notificationMode;

  /// Whether to automatically register the FCM/APNs token when the WebView
  /// finishes loading.
  final bool autoRegisterToken;

  /// Fine-grained notification configuration (sound, quiet hours, grouping,
  /// preview length, etc.).
  final YourGPTNotificationConfig? notificationConfig;

  const YourGPTConfig({
    required this.widgetUid,
    this.debug = false,
    this.customParams = const {},
    this.enableNotifications = false,
    this.notificationMode = NotificationMode.minimalist,
    this.autoRegisterToken = true,
    this.notificationConfig,
  });

  /// Creates a copy of this config with updated fields.
  YourGPTConfig copyWith({
    String? widgetUid,
    bool? debug,
    Map<String, String>? customParams,
    bool? enableNotifications,
    NotificationMode? notificationMode,
    bool? autoRegisterToken,
    YourGPTNotificationConfig? notificationConfig,
  }) {
    return YourGPTConfig(
      widgetUid: widgetUid ?? this.widgetUid,
      debug: debug ?? this.debug,
      customParams: customParams ?? this.customParams,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      notificationMode: notificationMode ?? this.notificationMode,
      autoRegisterToken: autoRegisterToken ?? this.autoRegisterToken,
      notificationConfig: notificationConfig ?? this.notificationConfig,
    );
  }

  /// Returns a new config with [additionalParams] merged into [customParams].
  ///
  /// Keys in [additionalParams] take precedence over existing [customParams].
  YourGPTConfig withParams(Map<String, String> additionalParams) {
    return copyWith(
      customParams: {...customParams, ...additionalParams},
    );
  }

  /// Returns a new config with notification settings applied.
  YourGPTConfig withNotifications({
    bool enabled = true,
    NotificationMode mode = NotificationMode.minimalist,
    YourGPTNotificationConfig? config,
  }) {
    return copyWith(
      enableNotifications: enabled,
      notificationMode: mode,
      notificationConfig: config,
    );
  }
}

// ---------------------------------------------------------------------------
// YourGPTConfigBuilder
// ---------------------------------------------------------------------------

/// Builds the full widget URL from a [YourGPTConfig].
class YourGPTConfigBuilder {
  final YourGPTConfig _config;

  const YourGPTConfigBuilder(this._config);

  /// Computes the complete set of query parameters for the widget URL.
  Map<String, String> _getQueryParams() {
    return {
      // Custom params first (lower precedence)
      ..._config.customParams,
      // SDK metadata (higher precedence — these must always be present)
      'sdk': _SDK.platform,
      'sdkVersion': _SDK.version,
      'mobileWebView': 'true',
    };
  }

  /// Builds and returns the complete widget [Uri].
  Uri buildWidgetURL() {
    return YourGPTSDKConfig.endpoints.widgetURLWithParams(
      _config.widgetUid,
      _getQueryParams(),
    );
  }

  /// Returns the underlying [YourGPTConfig].
  YourGPTConfig getConfig() => _config;

  /// Returns a new builder with [additionalParams] merged in.
  YourGPTConfigBuilder withParams(Map<String, String> additionalParams) {
    return YourGPTConfigBuilder(_config.withParams(additionalParams));
  }
}

/// Convenience factory for creating a [YourGPTConfigBuilder] from a config.
YourGPTConfigBuilder createConfig(YourGPTConfig config) {
  return YourGPTConfigBuilder(config);
}
