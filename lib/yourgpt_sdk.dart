import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'config.dart';

// Re-export config classes for convenience
export 'config.dart' show YourGPTConfig, YourGPTSDKConfig, YourGPTConfigBuilder, createConfig;

enum YourGPTConnectionState { disconnected, connecting, connected, error }

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
    YourGPTConnectionState? connectionState,
  }) {
    return YourGPTSDKState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}

class YourGPTSDK {
  static YourGPTSDK? _instance;
  static YourGPTSDK get instance => _instance ??= YourGPTSDK._();
  
  YourGPTSDK._();

  YourGPTConfig? _config;
  YourGPTSDKState _state = const YourGPTSDKState();
  
  final Map<String, List<Function>> _listeners = {};
  final StreamController<YourGPTSDKState> _stateController = 
      StreamController<YourGPTSDKState>.broadcast();

  Stream<YourGPTSDKState> get stateStream => _stateController.stream;
  YourGPTSDKState get state => _state;
  YourGPTConfig? get config => _config;

  Future<void> initialize(YourGPTConfig config) async {
    _log('Initializing SDK with config: ${config.widgetUid}');
    
    if (config.widgetUid.isEmpty) {
      throw ArgumentError('widgetUid is required for initialization');
    }

    _setState(_state.copyWith(
      isLoading: true,
      error: null,
      connectionState: YourGPTConnectionState.connecting,
    ));

    try {
      _config = config;
      
      // Validate widget existence
      await _validateWidget();
      
      _setState(_state.copyWith(
        isInitialized: true,
        isLoading: false,
        connectionState: YourGPTConnectionState.connected,
      ));
      
      _emit('sdk:initialized', config);
      _log('SDK initialized successfully');
    } catch (error) {
      final errorMessage = error.toString();
      _setState(_state.copyWith(
        isLoading: false,
        error: errorMessage,
        connectionState: YourGPTConnectionState.error,
      ));
      _emit('sdk:error', errorMessage);
      rethrow;
    }
  }

  Future<void> _validateWidget() async {
    if (_config == null) throw StateError('SDK not configured');
    
    // Simulate widget validation with API call
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (_config!.widgetUid.length < 3) {
      throw ArgumentError('Invalid widget UID');
    }
  }

  String buildWidgetUrl([Map<String, String>? additionalParams]) {
    if (_config == null) {
      throw StateError('SDK not initialized');
    }
    
    if (!isReady) {
      throw StateError('SDK not ready');
    }

    final configBuilder = createConfig(_config!);
    final urlBuilder = additionalParams != null 
        ? configBuilder.withParams(additionalParams) 
        : configBuilder;
    
    return urlBuilder.buildWidgetURL().toString();
  }

  bool get isReady => 
      _state.isInitialized && 
      !_state.isLoading && 
      _state.error == null;

  // Event system
  void on(String event, Function callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void off(String event, Function callback) {
    final eventListeners = _listeners[event];
    eventListeners?.remove(callback);
  }

  void _emit(String event, [dynamic data]) {
    final eventListeners = _listeners[event];
    if (eventListeners != null) {
      for (final callback in eventListeners) {
        try {
          callback(data);
        } catch (e) {
          debugPrint('Error in event callback: $e');
        }
      }
    }
  }

  Future<void> setUserContext(Map<String, dynamic> context) async {
    _log('Setting user context: $context');
    _emit('sdk:userContextSet', context);
  }

  Future<void> updateConfig(YourGPTConfig newConfig) async {
    if (!_state.isInitialized) {
      throw StateError('SDK not initialized');
    }
    
    _config = newConfig;
    _emit('sdk:configUpdated', newConfig);
  }

  void _setState(YourGPTSDKState newState) {
    _state = newState;
    _stateController.add(_state);
    _emit('sdk:stateChanged', _state);
  }

  void _log(String message) {
    if (_config?.debug == true) {
      debugPrint('[YourGPTSDK] $message');
    }
  }

  void destroy() {
    _log('Destroying SDK instance');
    _config = null;
    _state = const YourGPTSDKState();
    _listeners.clear();
    _stateController.close();
    _instance = null;
  }
}