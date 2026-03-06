/// Structured error types for the YourGPT Flutter SDK.
///
/// Mirrors the sealed error hierarchy from the Android and iOS SDKs.
library yourgpt_errors;

/// Base class for all YourGPT SDK errors.
abstract class YourGPTError implements Exception {
  const YourGPTError();

  String get message;

  @override
  String toString() => message;
}

/// Thrown when the SDK is given an invalid or incomplete configuration.
///
/// Typically occurs when [widgetUid] is empty or too short.
class InvalidConfigurationError extends YourGPTError {
  final String _detail;
  const InvalidConfigurationError(this._detail);

  @override
  String get message => 'InvalidConfiguration: $_detail';
}

/// Thrown when an SDK method is called before [YourGPTSDK.initialize].
class NotInitializedError extends YourGPTError {
  const NotInitializedError();

  @override
  String get message =>
      'SDK is not initialized. Call YourGPTSDK.initialize() or '
      'YourGPTSDK.quickInitialize() first.';
}

/// Thrown when the SDK is still loading and cannot service the request yet.
class NotReadyError extends YourGPTError {
  const NotReadyError();

  @override
  String get message =>
      'SDK is not ready. Wait for initialization to complete before '
      'calling this method.';
}

/// Thrown when a valid widget URL cannot be constructed.
class InvalidURLError extends YourGPTError {
  const InvalidURLError();

  @override
  String get message => 'Failed to build a valid widget URL. '
      'Check the widgetUid and customParams values in your YourGPTConfig.';
}

/// Thrown when the WebView encounters a navigation or resource error.
class WebViewLoadError extends YourGPTError {
  final String _detail;
  const WebViewLoadError(this._detail);

  @override
  String get message => 'WebView error: $_detail';
}
