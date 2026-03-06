/// Abstract event listener for the YourGPT Flutter SDK.
///
/// Mirrors [YourGPTEventListener] (Android interface) and
/// [YourGPTEventListener] protocol (iOS).
///
/// Register a listener on the SDK singleton:
/// ```dart
/// YourGPTSDK.instance.setEventListener(MyListener());
/// ```
///
/// Required methods cover chat widget lifecycle events.
/// All other methods have empty default implementations so you only
/// override what your app needs.
abstract class YourGPTEventListener {
  // ---------------------------------------------------------------------------
  // Widget lifecycle events — must implement
  // ---------------------------------------------------------------------------

  /// Called when a new message is received from the chatbot.
  ///
  /// [message] is the raw payload map from the widget, typically containing
  /// a `text` key with the message body.
  void onMessageReceived(Map<String, dynamic> message);

  /// Called when a message is successfully sent by the user.
  void onMessageSent(Map<String, dynamic> message) {}

  /// Called when the chat interface becomes visible / is opened.
  void onChatOpened();

  /// Called when the chat interface is closed (either by the user tapping
  /// the close button or by calling [Navigator.pop]).
  void onChatClosed();

  /// Called when any error occurs in the SDK or WebView.
  void onError(String error);

  /// Called when the WebView begins loading the widget URL.
  void onLoadingStarted();

  /// Called when the WebView finishes loading and the widget is ready.
  void onLoadingFinished();

  // ---------------------------------------------------------------------------
  // Connection events — optional
  // ---------------------------------------------------------------------------

  /// Called when the underlying WebSocket / chat connection is established.
  void onConnectionEstablished() {}

  /// Called when the connection drops.
  ///
  /// [reason] may contain a human-readable description of why the connection
  /// was lost, or `null` if unavailable.
  void onConnectionLost({String? reason}) {}

  /// Called when a previously lost connection is restored.
  void onConnectionRestored() {}

  // ---------------------------------------------------------------------------
  // Interaction events — optional
  // ---------------------------------------------------------------------------

  /// Called when the agent / bot starts typing.
  void onUserTyping() {}

  /// Called when the agent / bot stops typing.
  void onUserStoppedTyping() {}

  // ---------------------------------------------------------------------------
  // Escalation events — optional
  // ---------------------------------------------------------------------------

  /// Called when the conversation is escalated to a human agent.
  void onEscalationToHuman() {}

  /// Called when an escalated conversation is resolved and returned to the bot.
  void onEscalationResolved() {}

  // ---------------------------------------------------------------------------
  // Push notification events — optional (used in Phase 3)
  // ---------------------------------------------------------------------------

  /// Called when a push notification token (FCM or APNs) is received or
  /// refreshed.
  void onPushTokenReceived(String token) {}

  /// Called when a push notification message arrives while the app is in the
  /// foreground.
  void onPushMessageReceived(Map<String, dynamic> data) {}

  /// Called when the user taps a push notification to open the app.
  void onNotificationClicked(Map<String, dynamic> data) {}

  /// Called when the user grants push notification permission.
  void onNotificationPermissionGranted() {}

  /// Called when the user denies push notification permission.
  void onNotificationPermissionDenied() {}
}
