/// YourGPT SDK Configuration Constants
/// 
/// This file contains all the configuration constants used across the Flutter SDK.
/// DO NOT modify the base URL without proper coordination with the backend team.
library yourgpt_config;

/// YourGPT SDK Configuration
class YourGPTSDKConfig {
  /// Widget API endpoint configuration
  static const endpoints = _Endpoints._();
  
  /// SDK metadata
  static const sdk = _SDK._();
  
  /// Default configuration values
  static const defaults = _Defaults._();
}

/// Endpoint configuration
class _Endpoints {
  const _Endpoints._();
  
  /// Base widget URL - DO NOT CHANGE without coordination
  static const String widgetBase = 'https://widget.yourgpt.ai';
  
  /// Constructs the full widget URL with the provided widget UID
  /// Format: https://widget.yourgpt.ai/{widgetUid}
  /// Example: https://widget.yourgpt.ai/232d2602-7cbd-4f6a-87eb-21058599d594
  String widgetURL(String widgetUid) {
    return '$widgetBase/$widgetUid';
  }
  
  /// Constructs widget URL with query parameters
  Uri widgetURLWithParams(String widgetUid, Map<String, String> params) {
    final baseUrl = widgetURL(widgetUid);
    return Uri.parse(baseUrl).replace(queryParameters: params);
  }
}

/// SDK metadata
class _SDK {
  const _SDK._();
  
  static const String version = '1.0.0';
  static const String platform = 'Flutter';
  static const String name = 'YourGPT Flutter SDK';
}

/// Default configuration values
class _Defaults {
  const _Defaults._();

  static const bool debug = false;
  static const Duration timeout = Duration(seconds: 30);
}

/// Configuration class for initializing the SDK
class YourGPTConfig {
  /// Widget UID - required
  final String widgetUid;

  /// Enable debug logging
  final bool debug;

  /// Custom parameters to pass to the widget
  final Map<String, String> customParams;

  const YourGPTConfig({
    required this.widgetUid,
    this.debug = false,
    this.customParams = const {},
  });

  /// Creates a copy of this config with updated parameters
  YourGPTConfig copyWith({
    String? widgetUid,
    bool? debug,
    Map<String, String>? customParams,
  }) {
    return YourGPTConfig(
      widgetUid: widgetUid ?? this.widgetUid,
      debug: debug ?? this.debug,
      customParams: customParams ?? this.customParams,
    );
  }

  /// Merges additional parameters with the existing custom parameters
  YourGPTConfig withParams(Map<String, String> additionalParams) {
    final mergedParams = <String, String>{
      ...customParams,
      ...additionalParams,
    };
    return copyWith(customParams: mergedParams);
  }
}

/// Utility class for building widget URLs and managing configuration
class YourGPTConfigBuilder {
  final YourGPTConfig _config;
  
  const YourGPTConfigBuilder(this._config);
  
  /// Generates query parameters for the widget URL
  Map<String, String> _getQueryParams() {
    final params = <String, String>{};

    // Add custom parameters
    params.addAll(_config.customParams);

    // Add SDK metadata
    params['sdk'] = _SDK.platform;
    params['sdkVersion'] = _SDK.version;

    // Add Mobile parameter
    params['mobileWebView'] = 'true';

    return params;
  }
  
  /// Builds the complete widget URL with all parameters
  Uri buildWidgetURL() {
    return YourGPTSDKConfig.endpoints.widgetURLWithParams(
      _config.widgetUid,
      _getQueryParams(),
    );
  }
  
  /// Gets the configuration object
  YourGPTConfig getConfig() => _config;
  
  /// Updates the configuration with additional parameters
  YourGPTConfigBuilder withParams(Map<String, String> additionalParams) {
    return YourGPTConfigBuilder(_config.withParams(additionalParams));
  }
}

/// Creates a new configuration builder instance
YourGPTConfigBuilder createConfig(YourGPTConfig config) {
  return YourGPTConfigBuilder(config);
}