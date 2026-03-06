import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'yourgpt_sdk.dart';
import 'yourgpt_event_listener.dart';
import 'yourgpt_chat_controller.dart';
import 'yourgpt_device_info.dart';
import 'yourgpt_error.dart';
import 'yourgpt_notification_client.dart';

// ---------------------------------------------------------------------------
// YourGPTChatScreen
// ---------------------------------------------------------------------------

/// A Flutter widget that renders the YourGPT chat interface inside a WebView.
///
/// ## Basic usage — bottom sheet
/// ```dart
/// YourGPTChatScreen.showAsBottomSheet(
///   context: context,
///   widgetUid: 'your-widget-uid',
/// );
/// ```
///
/// ## Embedded usage
/// ```dart
/// YourGPTChatScreen(widgetUid: 'your-widget-uid')
/// ```
///
/// ## With controller (call methods from outside the widget)
/// ```dart
/// final controller = YourGPTChatController();
///
/// YourGPTChatScreen.showAsBottomSheet(
///   context: context,
///   widgetUid: 'your-widget-uid',
///   controller: controller,
/// );
///
/// controller.setSessionData({'orderId': 'ORD-123'});
/// ```
class YourGPTChatScreen extends StatefulWidget {
  // ---------------------------------------------------------------------------
  // Required
  // ---------------------------------------------------------------------------

  /// Your YourGPT widget UID (from the dashboard).
  final String widgetUid;

  // ---------------------------------------------------------------------------
  // Optional — callbacks (kept for backward compatibility)
  // ---------------------------------------------------------------------------

  /// Called when a new message is received from the chatbot.
  final Function(Map<String, dynamic>)? onMessage;

  /// Called when the chat interface is opened by the user.
  final VoidCallback? onChatOpened;

  /// Called when the chat interface is closed.
  final VoidCallback? onChatClosed;

  /// Called when any error occurs in the SDK or WebView.
  final Function(String)? onError;

  /// Called when the loading state changes.
  ///
  /// Receives `true` when loading begins and `false` when it ends.
  final Function(bool)? onLoading;

  // ---------------------------------------------------------------------------
  // Optional — additional callbacks (new in 1.1)
  // ---------------------------------------------------------------------------

  /// Called when a message is sent by the user.
  final Function(Map<String, dynamic>)? onMessageSent;

  /// Called when the WebSocket / chat connection is established.
  final VoidCallback? onConnectionEstablished;

  /// Called when the connection drops.
  ///
  /// [String?] is the reason string if provided by the widget.
  final Function(String?)? onConnectionLost;

  /// Called when a dropped connection is restored.
  final VoidCallback? onConnectionRestored;

  /// Called when the agent / bot starts typing.
  final VoidCallback? onTyping;

  /// Called when the agent / bot stops typing.
  final VoidCallback? onTypingStopped;

  /// Called when the conversation is escalated to a human agent.
  final VoidCallback? onEscalationToHuman;

  /// Called when an escalated conversation is resolved.
  final VoidCallback? onEscalationResolved;

  // ---------------------------------------------------------------------------
  // Optional — UI customisation
  // ---------------------------------------------------------------------------

  /// Override the default loading indicator.
  final Widget? customLoadingWidget;

  /// Override the default error view.
  ///
  /// Receives the error message string and a [VoidCallback] that retries the
  /// last operation when invoked.
  final Widget Function(String error, VoidCallback retry)? customErrorWidget;

  // ---------------------------------------------------------------------------
  // Optional — controller & listener
  // ---------------------------------------------------------------------------

  /// Controller for calling chat methods (setSessionData, openSession, etc.)
  /// from outside the widget tree.
  final YourGPTChatController? controller;

  /// Global event listener — fires the same events as the callbacks above but
  /// via a structured [YourGPTEventListener] interface.
  final YourGPTEventListener? eventListener;

  // ---------------------------------------------------------------------------
  // Optional — session
  // ---------------------------------------------------------------------------

  /// Opens the widget directly to this conversation UID.
  ///
  /// Useful when deep-linking from a push notification tap.
  final String? initialSessionUid;

  // ---------------------------------------------------------------------------
  // Optional — debug
  // ---------------------------------------------------------------------------

  /// Enable verbose SDK logging.
  final bool debug;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  const YourGPTChatScreen({
    Key? key,
    required this.widgetUid,
    this.onMessage,
    this.onChatOpened,
    this.onChatClosed,
    this.onError,
    this.onLoading,
    this.onMessageSent,
    this.onConnectionEstablished,
    this.onConnectionLost,
    this.onConnectionRestored,
    this.onTyping,
    this.onTypingStopped,
    this.onEscalationToHuman,
    this.onEscalationResolved,
    this.customLoadingWidget,
    this.customErrorWidget,
    this.controller,
    this.eventListener,
    this.initialSessionUid,
    this.debug = false,
  }) : super(key: key);

  // ---------------------------------------------------------------------------
  // Static helpers
  // ---------------------------------------------------------------------------

  /// Shows the chat widget as a full-height modal bottom sheet.
  ///
  /// This is the recommended way to present the chat widget.
  static Future<void> showAsBottomSheet({
    required BuildContext context,
    required String widgetUid,
    Function(Map<String, dynamic>)? onMessage,
    VoidCallback? onChatOpened,
    VoidCallback? onChatClosed,
    Function(String)? onError,
    Function(bool)? onLoading,
    Function(Map<String, dynamic>)? onMessageSent,
    VoidCallback? onConnectionEstablished,
    Function(String?)? onConnectionLost,
    VoidCallback? onConnectionRestored,
    VoidCallback? onTyping,
    VoidCallback? onTypingStopped,
    VoidCallback? onEscalationToHuman,
    VoidCallback? onEscalationResolved,
    Widget? customLoadingWidget,
    Widget Function(String error, VoidCallback retry)? customErrorWidget,
    YourGPTChatController? controller,
    YourGPTEventListener? eventListener,
    String? initialSessionUid,
    bool debug = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (BuildContext ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height,
          child: YourGPTChatScreen(
            widgetUid: widgetUid,
            onMessage: onMessage,
            onChatOpened: onChatOpened,
            onChatClosed: onChatClosed,
            onError: onError,
            onLoading: onLoading,
            onMessageSent: onMessageSent,
            onConnectionEstablished: onConnectionEstablished,
            onConnectionLost: onConnectionLost,
            onConnectionRestored: onConnectionRestored,
            onTyping: onTyping,
            onTypingStopped: onTypingStopped,
            onEscalationToHuman: onEscalationToHuman,
            onEscalationResolved: onEscalationResolved,
            customLoadingWidget: customLoadingWidget,
            customErrorWidget: customErrorWidget,
            controller: controller,
            eventListener: eventListener,
            initialSessionUid: initialSessionUid,
            debug: debug,
          ),
        );
      },
    );
  }

  /// Opens the chat widget directly to a specific conversation.
  ///
  /// Convenience wrapper around [showAsBottomSheet] that pre-selects the
  /// conversation identified by [sessionUid]. Typically called from a push
  /// notification tap handler.
  static Future<void> openSession({
    required BuildContext context,
    required String widgetUid,
    required String sessionUid,
    YourGPTChatController? controller,
    YourGPTEventListener? eventListener,
  }) {
    return showAsBottomSheet(
      context: context,
      widgetUid: widgetUid,
      initialSessionUid: sessionUid,
      controller: controller,
      eventListener: eventListener,
    );
  }

  @override
  State<YourGPTChatScreen> createState() => _YourGPTChatScreenState();
}

// ---------------------------------------------------------------------------
// _YourGPTChatScreenState
// ---------------------------------------------------------------------------

class _YourGPTChatScreenState extends State<YourGPTChatScreen> {
  WebViewController? _controller;
  final YourGPTSDK _sdk = YourGPTSDK.instance;

  bool _isSDKReady = false;
  bool _isLoading = true;
  bool _isWebViewLoaded = false;
  String? _error;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Attach the controller so callers can invoke methods on us.
    widget.controller?.attach(
      setSessionData: setSessionData,
      setVisitorData: setVisitorData,
      setContactData: setContactData,
      openSession: openSession,
      sendMessage: sendMessage,
      openChat: openChat,
    );

    // Defer initialisation so it doesn't block the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSDK();
    });
  }

  @override
  void dispose() {
    widget.controller?.detach();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SDK / WebView initialisation
  // ---------------------------------------------------------------------------

  Future<void> _initializeSDK() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    _fireLoading(true);

    try {
      final config = YourGPTConfig(
        widgetUid: widget.widgetUid,
        debug: widget.debug,
        enableNotifications: YourGPTNotificationClient.instance.isInitialized,
      );

      await _sdk.initialize(config);

      if (!mounted) return;

      setState(() {
        _isSDKReady = true;
        _error = null;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      _initializeWebView();
    } on YourGPTError catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to initialize SDK: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fireLoading(false);
      }
    }
  }

  void _initializeWebView() {
    if (!_sdk.isReady || !mounted) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _isWebViewLoaded = false;
            });
            _fireListener((l) => l.onLoadingStarted());
          },
          onPageFinished: (_) async {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _isWebViewLoaded = true;
            });
            _fireListener((l) => l.onLoadingFinished());

            // Small delay to ensure the page JS is ready.
            await Future.delayed(const Duration(milliseconds: 200));
            if (!mounted || _controller == null) return;

            _injectJavaScript();

            // Register the FCM/APNs token if notifications are enabled and
            // auto-registration is configured.
            final cfg = _sdk.config;
            if (cfg != null &&
                cfg.enableNotifications &&
                cfg.autoRegisterToken &&
                YourGPTNotificationClient.instance.isInitialized) {
              await YourGPTNotificationClient.instance
                  .registerTokenViaWebView(_controller!);
            }

            // If an initial session was requested, navigate to it.
            if (widget.initialSessionUid != null) {
              openSession(widget.initialSessionUid!);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted) return;
            // Only treat main-frame failures as fatal errors.
            // Sub-resource errors (fonts, analytics, images) should not
            // show the full error screen.
            if (error.isForMainFrame != true) {
              debugPrint('[YourGPTChatScreen] Sub-resource error: ${error.description}');
              return;
            }
            final msg = 'WebView error: ${error.description}';
            _setError(msg);
            _fireListener((l) => l.onError(msg));
          },
        ),
      )
      ..addJavaScriptChannel(
        'YourGPTNative',
        onMessageReceived: (JavaScriptMessage msg) {
          if (mounted) _handleMessage(msg.message);
        },
      )
      ..loadRequest(Uri.parse(_buildUrl()));
  }

  String _buildUrl() {
    final additionalParams = <String, String>{};

    // Append session UID as a query parameter so the widget can open the
    // right conversation on first load.
    if (widget.initialSessionUid != null) {
      additionalParams['session_uid'] = widget.initialSessionUid!;
    }

    return _sdk.buildWidgetUrl(
      additionalParams.isNotEmpty ? additionalParams : null,
    );
  }

  // ---------------------------------------------------------------------------
  // JavaScript bridge injection
  // ---------------------------------------------------------------------------

  void _injectJavaScript() {
    _controller?.runJavaScript('''
      // -----------------------------------------------------------------------
      // Route all postMessage events from the widget back to Flutter.
      // -----------------------------------------------------------------------
      if (!window.__yourgpt_bridge_injected) {
        window.__yourgpt_bridge_injected = true;

        window.addEventListener('message', function(event) {
          if (!event.data) return;
          var payload;
          if (typeof event.data === 'string') {
            payload = JSON.stringify({ type: event.data });
          } else if (typeof event.data === 'object') {
            payload = JSON.stringify(event.data);
          }
          if (payload) {
            YourGPTNative.postMessage(payload);
          }
        });
      }

      // -----------------------------------------------------------------------
      // Native bridge — Dart calls window.postMessage() via runJavaScript;
      // the widget listens for these message types.
      // -----------------------------------------------------------------------
      window.nativeBridge = {
        /** Send a text message to the chatbot. */
        sendMessage: function(message) {
          window.postMessage({ type: 'native:sendMessage', payload: message }, '*');
        },
        /** Set generic user context. */
        setUserContext: function(context) {
          window.postMessage({ type: 'native:setUserContext', payload: context }, '*');
        },
        /** Set session-specific data (orderId, plan, etc.). */
        setSessionData: function(data) {
          window.postMessage({ type: 'native:setSessionData', payload: data }, '*');
        },
        /** Set visitor info — device metadata is merged in automatically. */
        setVisitorData: function(data) {
          window.postMessage({ type: 'native:setVisitorData', payload: data }, '*');
        },
        /** Set contact info (email, phone, etc.). */
        setContactData: function(data) {
          window.postMessage({ type: 'native:setContactData', payload: data }, '*');
        },
        /** Navigate the widget to a specific conversation. */
        openSession: function(sessionUid) {
          window.postMessage({ type: 'open_session', payload: { session_uid: sessionUid } }, '*');
        },
        /** Programmatically open the chat interface. */
        openChat: function() {
          window.postMessage({ type: 'openChat' }, '*');
        }
      };
    ''');
  }

  // ---------------------------------------------------------------------------
  // Message handling (WebView → Dart)
  // ---------------------------------------------------------------------------

  void _handleMessage(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final payload = data['payload'];

      switch (type) {
        // ---- Messages -------------------------------------------------------
        case 'message:received':
        case 'message:new':
          final msg = payload is Map<String, dynamic> ? payload : {'text': payload?.toString() ?? ''};
          widget.onMessage?.call(msg);
          _fireListener((l) => l.onMessageReceived(msg));

        case 'message:sent':
          final msg = payload is Map<String, dynamic> ? payload : {'text': payload?.toString() ?? ''};
          widget.onMessageSent?.call(msg);
          _fireListener((l) => l.onMessageSent(msg));

        // ---- Chat open / close ----------------------------------------------
        case 'chat:opened':
        case 'widget:opened':
          widget.onChatOpened?.call();
          _fireListener((l) => l.onChatOpened());

        case 'chat:closed':
        case 'widget:closed':
          widget.onChatClosed?.call();
          _fireListener((l) => l.onChatClosed());

        case 'chatbot-close':
          widget.onChatClosed?.call();
          _fireListener((l) => l.onChatClosed());
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

        // ---- Connection -----------------------------------------------------
        case 'connection:established':
        case 'sdk:initialized':
        case 'webview:loaded':
          widget.onConnectionEstablished?.call();
          _fireListener((l) => l.onConnectionEstablished());

        case 'connection:lost':
          final reason = payload is Map ? payload['reason'] as String? : null;
          widget.onConnectionLost?.call(reason);
          _fireListener((l) => l.onConnectionLost(reason: reason));

        case 'connection:restored':
          widget.onConnectionRestored?.call();
          _fireListener((l) => l.onConnectionRestored());

        // ---- Typing ---------------------------------------------------------
        case 'user:typing':
          widget.onTyping?.call();
          _fireListener((l) => l.onUserTyping());

        case 'user:stopped_typing':
          widget.onTypingStopped?.call();
          _fireListener((l) => l.onUserStoppedTyping());

        // ---- Escalation -----------------------------------------------------
        case 'escalation:to_human':
          widget.onEscalationToHuman?.call();
          _fireListener((l) => l.onEscalationToHuman());

        case 'escalation:resolved':
          widget.onEscalationResolved?.call();
          _fireListener((l) => l.onEscalationResolved());

        // ---- Errors ---------------------------------------------------------
        case 'error:occurred':
        case 'error:network':
          final msg = payload is Map
              ? (payload['message'] as String? ?? 'Widget error')
              : (payload?.toString() ?? 'Widget error');
          widget.onError?.call(msg);
          _fireListener((l) => l.onError(msg));

        default:
          // Unknown event — ignore silently.
          break;
      }
    } catch (e) {
      debugPrint('[YourGPTChatScreen] Error parsing WebView message: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Public methods (also exposed via YourGPTChatController)
  // ---------------------------------------------------------------------------

  /// Sends session-specific context data to the widget.
  void setSessionData(Map<String, dynamic> data) {
    _postMessage('native:setSessionData', data);
  }

  /// Sends visitor information to the widget.
  ///
  /// Auto-enriches [data] with platform, device model, OS version, and app
  /// version before forwarding to the widget.
  void setVisitorData(Map<String, dynamic> data) async {
    final deviceInfo = await YourGPTDeviceInfo.getDeviceInfo();
    final enriched = {...deviceInfo, ...data}; // data overrides device defaults
    _postMessage('native:setVisitorData', enriched);
  }

  /// Sends contact information (email, phone, etc.) to the widget.
  void setContactData(Map<String, dynamic> data) {
    _postMessage('native:setContactData', data);
  }

  /// Navigates the widget to a specific conversation by [sessionUid].
  void openSession(String sessionUid) {
    _postMessage('open_session', {'session_uid': sessionUid});
  }

  /// Sends a text message to the chatbot programmatically.
  void sendMessage(String message) {
    _postMessage('native:sendMessage', message);
  }

  /// Programmatically opens / focuses the chat interface.
  void openChat() {
    _controller?.runJavaScript(
      "window.postMessage({ type: 'openChat' }, '*');",
    );
  }

  void _postMessage(String type, dynamic payload) {
    if (_controller == null) return;
    final payloadJson = jsonEncode(payload);
    _controller!.runJavaScript('''
      window.postMessage({ type: '$type', payload: $payloadJson }, '*');
    ''');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    widget.onError?.call(message);
  }

  void _fireLoading(bool loading) {
    widget.onLoading?.call(loading);
    if (loading) {
      _fireListener((l) => l.onLoadingStarted());
    } else {
      _fireListener((l) => l.onLoadingFinished());
    }
  }

  void _fireListener(void Function(YourGPTEventListener) fn) {
    final local = widget.eventListener;
    if (local != null) fn(local);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError(_error!);
    if (!_isSDKReady) return _buildSimpleMessage('SDK not ready');
    if (!_isWebViewLoaded) return _buildLoading();
    if (_controller == null) return _buildSimpleMessage('WebView not initialized');

    return Container(
      height: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: WebViewWidget(controller: _controller!),
      ),
    );
  }

  Widget _buildLoading() {
    return widget.customLoadingWidget ??
        Container(
          color: Colors.white,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Connecting to AI Assistant',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Just a moment while we set things up…',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildError(String error) {
    if (widget.customErrorWidget != null) {
      return widget.customErrorWidget!(error, _initializeSDK);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeSDK,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleMessage(String message) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.red),
        ),
      ),
    );
  }
}
