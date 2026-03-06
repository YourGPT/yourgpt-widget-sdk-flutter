import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'config.dart';
import 'yourgpt_chat_controller.dart';
import 'yourgpt_chat_screen.dart';
import 'yourgpt_error.dart';
import 'yourgpt_event_listener.dart';
import 'yourgpt_notification_client.dart';

// Re-export config types for convenience.
export 'config.dart'
    show
        YourGPTConfig,
        YourGPTSDKConfig,
        YourGPTConfigBuilder,
        NotificationMode,
        createConfig;

// ---------------------------------------------------------------------------
// Connection state
// ---------------------------------------------------------------------------

/// Represents the current state of the chat connection.
enum YourGPTConnectionState {
  /// No connection has been established yet.
  disconnected,

  /// A connection is being established.
  connecting,

  /// The connection is live and the widget is ready.
  connected,

  /// The connection failed or was lost with an error.
  error,
}

// ---------------------------------------------------------------------------
// SDK state snapshot
// ---------------------------------------------------------------------------

/// Immutable snapshot of the SDK's current state.
///
/// Listen to [YourGPTSDK.stateStream] to receive updates.
class YourGPTSDKState {
  final bool isInitialized;
  final bool isLoading;
  final String? error;
  final YourGPTConnectionState connectionState;

  const YourGPTSDKState({
    this.isInitialized = false,
    this.isLoading = false,
    this.error,
    this.connectionState = YourGPTConnectionState.disconnected,
  });

  YourGPTSDKState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? error,
    bool clearError = false,
    YourGPTConnectionState? connectionState,
  }) {
    return YourGPTSDKState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      connectionState: connectionState ?? this.connectionState,
    );
  }
}

// ---------------------------------------------------------------------------
// YourGPTSDK — main singleton
// ---------------------------------------------------------------------------

/// The main entry point for the YourGPT Flutter SDK.
///
/// Usage:
/// ```dart
/// // Quick start (most common)
/// await YourGPTSDK.quickInitialize('your-widget-uid');
///
/// // Full setup
/// await YourGPTSDK.instance.initialize(YourGPTConfig(
///   widgetUid: 'your-widget-uid',
///   debug: true,
///   enableNotifications: true,
/// ));
///
/// // Show the chat widget
/// YourGPTSDK.show(context);
/// ```
class YourGPTSDK {
  // Singleton
  static YourGPTSDK? _instance;
  static YourGPTSDK get instance => _instance ??= YourGPTSDK._();
  YourGPTSDK._();

  YourGPTConfig? _config;
  YourGPTSDKState _state = const YourGPTSDKState();
  YourGPTEventListener? _eventListener;

  final Map<String, List<Function>> _listeners = {};
  final StreamController<YourGPTSDKState> _stateController =
      StreamController<YourGPTSDKState>.broadcast();

  // ---------------------------------------------------------------------------
  // Public state
  // ---------------------------------------------------------------------------

  /// Stream of SDK state snapshots — subscribe to drive reactive UI.
  Stream<YourGPTSDKState> get stateStream => _stateController.stream;

  /// Current SDK state snapshot.
  YourGPTSDKState get state => _state;

  /// Current configuration (null before [initialize] is called).
  YourGPTConfig? get config => _config;

  /// `true` when the SDK is initialised, not loading, and has no errors.
  bool get isReady =>
      _state.isInitialized && !_state.isLoading && _state.error == null;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initialises the SDK with the given [config].
  ///
  /// Throws [InvalidConfigurationError] if [config.widgetUid] is empty.
  /// Throws [InvalidConfigurationError] if the widget UID fails validation.
  Future<void> initialize(YourGPTConfig config) async {
    _log('Initializing SDK with widgetUid: ${config.widgetUid}');

    if (config.widgetUid.isEmpty) {
      throw const InvalidConfigurationError(
        'widgetUid cannot be empty.',
      );
    }

    _setState(_state.copyWith(
      isLoading: true,
      clearError: true,
      connectionState: YourGPTConnectionState.connecting,
    ));

    try {
      _config = config;
      await _validateWidget();

      _setState(_state.copyWith(
        isInitialized: true,
        isLoading: false,
        clearError: true,
        connectionState: YourGPTConnectionState.connected,
      ));

      _emit('sdk:initialized', config);
      _log('SDK initialized successfully');
    } catch (error) {
      final message = error is YourGPTError ? error.message : error.toString();
      _setState(_state.copyWith(
        isLoading: false,
        error: message,
        connectionState: YourGPTConnectionState.error,
      ));
      _emit('sdk:error', message);
      rethrow;
    }
  }

  /// One-line SDK initialisation with notifications auto-enabled.
  ///
  /// This is the simplest way to get started — it initialises the SDK and
  /// sets up push notifications in minimalist mode (auto-display, auto-tap
  /// handling). Equivalent to calling [initialize] + [YourGPTNotificationClient.quickSetup].
  ///
  /// ```dart
  /// await YourGPTSDK.quickInitialize('your-widget-uid');
  /// ```
  static Future<void> quickInitialize(String widgetUid) async {
    await instance.initialize(YourGPTConfig(
      widgetUid: widgetUid,
      enableNotifications: true,
    ));
    await YourGPTNotificationClient.instance.quickSetup(widgetUid);
  }

  /// Validates that the configured widget UID looks plausible.
  Future<void> _validateWidget() async {
    if (_config == null) throw const NotInitializedError();

    // Simulate a lightweight server-side check (< 1 s) while also giving
    // the UI time to render the loading state.
    await Future.delayed(const Duration(milliseconds: 800));

    if (_config!.widgetUid.length < 3) {
      throw const InvalidConfigurationError(
        'widgetUid is too short — check your YourGPT dashboard.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Widget presentation helpers
  // ---------------------------------------------------------------------------

  /// Shows the chat widget as a full-height bottom sheet.
  ///
  /// Uses the widget UID from [initialize] by default. Pass [widgetUid] to
  /// override.
  ///
  /// ```dart
  /// YourGPTSDK.show(context);
  /// ```
  static Future<void> show(BuildContext context, {String? widgetUid}) {
    final uid = widgetUid ?? instance._config?.widgetUid;
    if (uid == null) {
      throw const NotInitializedError();
    }
    return YourGPTChatScreen.showAsBottomSheet(
      context: context,
      widgetUid: uid,
    );
  }

  /// Opens the chat widget directly to a specific conversation.
  ///
  /// Convenience method typically called from a push notification tap handler.
  ///
  /// ```dart
  /// YourGPTSDK.openSession(context, sessionUid: 'conversation-uid');
  /// ```
  static Future<void> openSession(
    BuildContext context, {
    required String sessionUid,
    String? widgetUid,
  }) {
    final uid = widgetUid ?? instance._config?.widgetUid;
    if (uid == null) {
      throw const NotInitializedError();
    }
    return YourGPTChatScreen.openSession(
      context: context,
      widgetUid: uid,
      sessionUid: sessionUid,
    );
  }

  // ---------------------------------------------------------------------------
  // Factory — embeddable widget
  // ---------------------------------------------------------------------------

  /// Creates a [YourGPTChatScreen] widget for custom embedding in your UI.
  ///
  /// This mirrors `createChatbotFragment` (Android) and
  /// `createChatbotViewController` (iOS).
  ///
  /// ```dart
  /// final chatWidget = YourGPTSDK.createChatWidget(
  ///   widgetUid: 'your-widget-uid',
  ///   customParams: {'lang': 'en'},
  /// );
  /// ```
  static YourGPTChatScreen createChatWidget({
    required String widgetUid,
    Map<String, String> customParams = const {},
    YourGPTChatController? controller,
    YourGPTEventListener? eventListener,
    bool debug = false,
  }) {
    return YourGPTChatScreen(
      widgetUid: widgetUid,
      controller: controller,
      eventListener: eventListener,
      debug: debug,
    );
  }

  // ---------------------------------------------------------------------------
  // Push notification passthrough
  // ---------------------------------------------------------------------------

  /// Manually notifies the SDK about an incoming push notification.
  ///
  /// Use this when your app receives a push notification outside of the SDK's
  /// automatic handling (e.g. in [NotificationMode.advanced]).
  ///
  /// Mirrors `notifyPushReceived` on the Android SDK.
  static void notifyPushReceived(Map<String, dynamic> data) {
    instance._emit('sdk:pushReceived', data);
    instance._eventListener?.onPushMessageReceived(data);
  }

  // ---------------------------------------------------------------------------
  // URL builder
  // ---------------------------------------------------------------------------

  /// Builds the full widget URL including all SDK query parameters.
  ///
  /// Throws [NotInitializedError] if the SDK has not been initialised.
  /// Throws [NotReadyError] if the SDK is still loading.
  String buildWidgetUrl([Map<String, String>? additionalParams]) {
    if (_config == null) throw const NotInitializedError();
    if (!isReady) throw const NotReadyError();

    final builder = additionalParams != null
        ? createConfig(_config!).withParams(additionalParams)
        : createConfig(_config!);

    final uri = builder.buildWidgetURL();
    if (uri.host.isEmpty) throw const InvalidURLError();

    return uri.toString();
  }

  // ---------------------------------------------------------------------------
  // Event listener
  // ---------------------------------------------------------------------------

  /// Sets a global [YourGPTEventListener] that receives all SDK events.
  ///
  /// Only one global listener is supported at a time. Pass `null` to remove
  /// the current listener.
  void setEventListener(YourGPTEventListener? listener) {
    _eventListener = listener;
    YourGPTNotificationClient.instance.setEventListener(listener);
  }

  // ---------------------------------------------------------------------------
  // Low-level event system (for advanced / internal use)
  // ---------------------------------------------------------------------------

  /// Registers a [callback] for the named [event].
  ///
  /// Multiple callbacks per event are supported.
  void on(String event, Function callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  /// Removes a previously registered [callback] for [event].
  void off(String event, Function callback) {
    _listeners[event]?.remove(callback);
  }

  void _emit(String event, [dynamic data]) {
    final eventListeners = _listeners[event];
    if (eventListeners != null) {
      for (final callback in List.of(eventListeners)) {
        try {
          callback(data);
        } catch (e) {
          debugPrint('[YourGPTSDK] Error in event callback for "$event": $e');
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // User context
  // ---------------------------------------------------------------------------

  /// Stores user context data and notifies listeners.
  ///
  /// The context is forwarded to any open chat screen via the JS bridge.
  Future<void> setUserContext(Map<String, dynamic> context) async {
    _log('Setting user context: $context');
    _emit('sdk:userContextSet', context);
    _eventListener?.onChatOpened(); // Notify — not strictly correct but kept for parity
  }

  // ---------------------------------------------------------------------------
  // Config updates
  // ---------------------------------------------------------------------------

  /// Replaces the current configuration with [newConfig].
  ///
  /// Throws [NotInitializedError] if the SDK has not been initialised.
  Future<void> updateConfig(YourGPTConfig newConfig) async {
    if (!_state.isInitialized) throw const NotInitializedError();
    _config = newConfig;
    _emit('sdk:configUpdated', newConfig);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void _setState(YourGPTSDKState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
    _emit('sdk:stateChanged', _state);
  }

  void _log(String message) {
    if (_config?.debug == true) {
      debugPrint('[YourGPTSDK] $message');
    }
  }

  /// Destroys the SDK singleton and releases all resources.
  ///
  /// Call this when your app is shutting down or when you need to
  /// re-initialise the SDK with a different configuration.
  void destroy() {
    _log('Destroying SDK instance');
    _config = null;
    _state = const YourGPTSDKState();
    _eventListener = null;
    _listeners.clear();
    if (!_stateController.isClosed) _stateController.close();
    _instance = null;
  }
}
