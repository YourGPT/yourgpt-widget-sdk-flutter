import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'yourgpt_sdk.dart';

class YourGPTChatScreen extends StatefulWidget {
  final String widgetUid;
  final Function(Map<String, dynamic>)? onMessage;
  final VoidCallback? onChatOpened;
  final VoidCallback? onChatClosed;
  final Function(String)? onError;
  final Function(bool)? onLoading;
  final Widget? customLoadingWidget;
  final Widget Function(String)? customErrorWidget;

  const YourGPTChatScreen({
    Key? key,
    required this.widgetUid,
    this.onMessage,
    this.onChatOpened,
    this.onChatClosed,
    this.onError,
    this.onLoading,
    this.customLoadingWidget,
    this.customErrorWidget,
  }) : super(key: key);

  /// Shows the YourGPT chat widget as a bottom sheet
  static Future<void> showAsBottomSheet({
    required BuildContext context,
    required String widgetUid,
    Function(Map<String, dynamic>)? onMessage,
    VoidCallback? onChatOpened,
    VoidCallback? onChatClosed,
    Function(String)? onError,
    Function(bool)? onLoading,
    Widget? customLoadingWidget,
    Widget Function(String)? customErrorWidget,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: const BoxDecoration(),
          child: Column(
            children: [
              Expanded(
                child: YourGPTChatScreen(
                  widgetUid: widgetUid,
                  onMessage: onMessage,
                  onChatOpened: onChatOpened,
                  onChatClosed: onChatClosed,
                  onError: onError,
                  onLoading: onLoading,
                  customLoadingWidget: customLoadingWidget,
                  customErrorWidget: customErrorWidget,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  State<YourGPTChatScreen> createState() => _YourGPTChatScreenState();
}

class _YourGPTChatScreenState extends State<YourGPTChatScreen> {
  late final WebViewController _controller;
  final YourGPTSDK _sdk = YourGPTSDK.instance;
  
  bool _isSDKReady = false;
  bool _isLoading = true;
  bool _isWebViewLoaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      widget.onLoading?.call(true);

      final config = YourGPTConfig(
        widgetUid: widget.widgetUid,
        debug: true,
      );

      await _sdk.initialize(config);

      setState(() {
        _isSDKReady = true;
        _error = null;
      });

      _initializeWebView();
    } catch (error) {
      final errorMessage = 'Failed to initialize SDK: $error';
      setState(() {
        _error = errorMessage;
      });
      widget.onError?.call(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
      widget.onLoading?.call(false);
    }
  }

  void _initializeWebView() {
    if (!_sdk.isReady) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _isWebViewLoaded = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _isWebViewLoaded = true;
            });
            _injectJavaScript();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error = 'WebView Error: ${error.description}';
              _isWebViewLoaded = false;
            });
            widget.onError?.call(_error!);
          },
        ),
      )
      ..addJavaScriptChannel(
        'YourGPTNative',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(_buildUrl()));
  }

  String _buildUrl() {
    if (!_sdk.isReady) {
      throw StateError('SDK not ready');
    }
    return _sdk.buildWidgetUrl();
  }

  void _injectJavaScript() {
    _controller.runJavaScript('''
      window.addEventListener('message', function(event) {
        if (event.data) {
          if (typeof event.data === 'string') {
            // Handle string messages (like "chatbot-close")
            YourGPTNative.postMessage(JSON.stringify({ type: event.data }));
          } else if (typeof event.data === 'object') {
            // Handle object messages
            YourGPTNative.postMessage(JSON.stringify(event.data));
          }
        }
      });

      window.nativeBridge = {
        sendMessage: function(message) {
          window.postMessage({ type: 'native:sendMessage', payload: message }, '*');
        },
        setUserContext: function(context) {
          window.postMessage({ type: 'native:setUserContext', payload: context }, '*');
        }
      };
    ''');
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;

      switch (data['type']) {
        case 'message:new':
          widget.onMessage?.call(data['payload']);
          break;
        case 'chat:opened':
          widget.onChatOpened?.call();
          break;
        case 'chat:closed':
          widget.onChatClosed?.call();
          break;
        case 'chatbot-close':
          // Close the bottom sheet when chatbot-close event is received
          Navigator.of(context).pop();
          break;
      }
    } catch (e) {
      debugPrint('Error parsing WebView message: $e');
    }
  }

  void sendMessage(String message) {
    _controller.runJavaScript('''
      window.postMessage({
        type: 'sendMessage',
        payload: '$message'
      }, '*');
    ''');
  }

  void setUserContext(Map<String, dynamic> context) {
    final contextJson = jsonEncode(context);
    _controller.runJavaScript('''
      window.postMessage({
        type: 'setUserContext',
        payload: $contextJson
      }, '*');
    ''');
  }

  void openChat() {
    _controller.runJavaScript('''
      window.postMessage({
        type: 'openChat'
      }, '*');
    ''');
  }

  Widget _buildLoadingWidget() {
    return widget.customLoadingWidget ??
        Container(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Initializing ChatBot...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildErrorWidget(String error) {
    return widget.customErrorWidget?.call(error) ??
        Container(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget(_error!);
    }

    if (!_isSDKReady) {
      return Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: const Center(
          child: Text(
            'SDK not ready',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    // Show loading state until WebView is fully loaded
    if (!_isWebViewLoaded) {
      return Container(
        height: double.infinity,
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading ChatBot...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}