/// Controller for programmatically interacting with a mounted
/// [YourGPTChatScreen] widget.
///
/// Pass an instance of this controller to [YourGPTChatScreen] (or to
/// [YourGPTChatScreen.showAsBottomSheet]) and use it to call methods on the
/// chat widget from any point in your widget tree — without needing a
/// [GlobalKey].
///
/// Example:
/// ```dart
/// final _chatController = YourGPTChatController();
///
/// // Open the chat
/// YourGPTChatScreen.showAsBottomSheet(
///   context: context,
///   widgetUid: 'your-widget-uid',
///   controller: _chatController,
/// );
///
/// // Later — from anywhere:
/// _chatController.setSessionData({'orderId': 'ORD-12345'});
/// _chatController.setContactData({'email': 'user@example.com'});
/// _chatController.openSession('session-uid-from-notification');
/// ```
class YourGPTChatController {
  // Internal callbacks set by _YourGPTChatScreenState when it mounts.
  void Function(Map<String, dynamic>)? _setSessionData;
  void Function(Map<String, dynamic>)? _setVisitorData;
  void Function(Map<String, dynamic>)? _setContactData;
  void Function(String)? _openSession;
  void Function(String)? _sendMessage;
  void Function()? _openChat;

  /// Whether this controller is currently attached to a live chat screen.
  bool get isAttached => _setSessionData != null;

  // ---------------------------------------------------------------------------
  // Internal attach / detach — called by _YourGPTChatScreenState
  // ---------------------------------------------------------------------------

  /// Called by the chat screen state when it initialises.
  void attach({
    required void Function(Map<String, dynamic>) setSessionData,
    required void Function(Map<String, dynamic>) setVisitorData,
    required void Function(Map<String, dynamic>) setContactData,
    required void Function(String) openSession,
    required void Function(String) sendMessage,
    required void Function() openChat,
  }) {
    _setSessionData = setSessionData;
    _setVisitorData = setVisitorData;
    _setContactData = setContactData;
    _openSession = openSession;
    _sendMessage = sendMessage;
    _openChat = openChat;
  }

  /// Called by the chat screen state when it disposes.
  void detach() {
    _setSessionData = null;
    _setVisitorData = null;
    _setContactData = null;
    _openSession = null;
    _sendMessage = null;
    _openChat = null;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Sends session-specific context data to the widget (e.g. orderId, plan).
  ///
  /// Has no effect if the controller is not attached to a visible chat screen.
  void setSessionData(Map<String, dynamic> data) {
    _setSessionData?.call(data);
  }

  /// Sends visitor information to the widget.
  ///
  /// Device metadata (platform, model, OS version, app version) is added
  /// automatically — you do not need to include it.
  ///
  /// Has no effect if the controller is not attached to a visible chat screen.
  void setVisitorData(Map<String, dynamic> data) {
    _setVisitorData?.call(data);
  }

  /// Sends contact information (e.g. email, phone) to the widget.
  ///
  /// Has no effect if the controller is not attached to a visible chat screen.
  void setContactData(Map<String, dynamic> data) {
    _setContactData?.call(data);
  }

  /// Navigates the widget to a specific conversation by [sessionUid].
  ///
  /// This is the primary entry point for opening a conversation from a push
  /// notification tap — call it from your notification click handler.
  ///
  /// Has no effect if the controller is not attached to a visible chat screen.
  void openSession(String sessionUid) {
    _openSession?.call(sessionUid);
  }

  /// Sends a text message to the chatbot programmatically.
  ///
  /// Has no effect if the controller is not attached to a visible chat screen.
  void sendMessage(String message) {
    _sendMessage?.call(message);
  }

  /// Programmatically opens / focuses the chat interface within the widget.
  ///
  /// Has no effect if the controller is not attached to a visible chat screen.
  void openChat() {
    _openChat?.call();
  }
}
