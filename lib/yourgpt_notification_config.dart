/// Defines a custom notification action button.
///
/// Mirrors `NotificationAction` from the Android and iOS SDKs.
///
/// Used with [YourGPTNotificationHelper.showActionNotification] to add
/// custom action buttons to notifications.
class NotificationAction {
  /// Unique identifier for this action (used to identify taps).
  final String identifier;

  /// The label displayed on the action button.
  final String title;

  /// Whether tapping this action brings the app to the foreground.
  final bool foreground;

  const NotificationAction({
    required this.identifier,
    required this.title,
    this.foreground = true,
  });
}

/// Notification appearance and behaviour configuration for the YourGPT SDK.
///
/// Mirrors [YourGPTNotificationConfig] from the Android and iOS SDKs.
///
/// Use this to customise how push notifications are displayed, grouped,
/// and filtered on both Android and iOS.
///
/// Example:
/// ```dart
/// final notifConfig = YourGPTNotificationConfig(
///   soundEnabled: true,
///   quietHoursEnabled: true,
///   quietHoursStart: 22,
///   quietHoursEnd: 8,
///   maxPreviewLength: 80,
/// );
/// ```
class YourGPTNotificationConfig {
  // ---------------------------------------------------------------------------
  // Basic
  // ---------------------------------------------------------------------------

  /// Whether notifications are enabled at all.
  ///
  /// Setting this to `false` acts as a master switch — no notifications will
  /// be shown regardless of other settings.
  final bool notificationsEnabled;

  // ---------------------------------------------------------------------------
  // Sound
  // ---------------------------------------------------------------------------

  /// Whether to play a sound when a notification arrives.
  final bool soundEnabled;

  /// Custom sound file name (without extension) from the app's bundle.
  ///
  /// Leave `null` to use the device's default notification sound.
  final String? soundName;

  // ---------------------------------------------------------------------------
  // Badge (iOS) / LED (Android analogue)
  // ---------------------------------------------------------------------------

  /// Whether to update the app's badge count on iOS when a notification
  /// arrives.
  final bool badgeEnabled;

  // ---------------------------------------------------------------------------
  // Vibration (Android)
  // ---------------------------------------------------------------------------

  /// Whether to vibrate when a notification arrives (Android).
  final bool vibrationEnabled;

  /// Custom vibration pattern in milliseconds (Android).
  ///
  /// Alternating off/on durations, e.g. `[0, 300, 200, 300]`.
  /// Leave `null` to use the default vibration.
  final List<int>? vibrationPattern;

  // ---------------------------------------------------------------------------
  // Grouping / threading
  // ---------------------------------------------------------------------------

  /// Whether to group multiple notifications from the same conversation into
  /// a single thread.
  final bool groupMessages;

  /// Prefix for the thread / group identifier.
  ///
  /// The full identifier is `{threadIdentifierPrefix}.{sessionUid}`.
  final String threadIdentifierPrefix;

  // ---------------------------------------------------------------------------
  // Auto-dismiss
  // ---------------------------------------------------------------------------

  /// Whether to automatically dismiss notifications when the user opens the
  /// chat widget from a notification tap.
  final bool autoDismissOnOpen;

  // ---------------------------------------------------------------------------
  // Quiet hours
  // ---------------------------------------------------------------------------

  /// Whether quiet hours are active.
  ///
  /// When `true`, notifications are suppressed between [quietHoursStart] and
  /// [quietHoursEnd].
  final bool quietHoursEnabled;

  /// The hour (24-hour clock) at which quiet hours begin.
  ///
  /// Defaults to `22` (10 PM).
  final int quietHoursStart;

  /// The hour (24-hour clock) at which quiet hours end.
  ///
  /// Defaults to `8` (8 AM). Overnight ranges (e.g. 22 → 8) are supported.
  final int quietHoursEnd;

  // ---------------------------------------------------------------------------
  // Message preview
  // ---------------------------------------------------------------------------

  /// Whether to show the message body in the notification.
  final bool showMessagePreview;

  /// Maximum number of characters to show in the notification body.
  ///
  /// Longer messages are truncated and suffixed with "…".
  final int maxPreviewLength;

  // ---------------------------------------------------------------------------
  // Reply action
  // ---------------------------------------------------------------------------

  /// Whether to add an inline-reply action to notifications.
  ///
  /// On Android this shows a "Reply" button in the notification shade.
  /// On iOS it adds a text reply action.
  final bool showReplyAction;

  // ---------------------------------------------------------------------------
  // Stacking
  // ---------------------------------------------------------------------------

  /// Whether to stack multiple notifications from the same widget rather than
  /// replacing them.
  final bool stackNotifications;

  /// Maximum number of stacked notifications before older ones are removed.
  final int maxNotificationStack;

  // ---------------------------------------------------------------------------
  // Android channel
  // ---------------------------------------------------------------------------

  /// Android notification channel ID.
  final String channelId;

  /// Android notification channel name (visible to users in system settings).
  final String channelName;

  /// Android notification channel description.
  final String channelDescription;

  // ---------------------------------------------------------------------------
  // Android — LED indicator
  // ---------------------------------------------------------------------------

  /// Whether to enable the notification LED indicator (Android).
  final bool ledEnabled;

  /// LED indicator color as an ARGB integer (Android).
  ///
  /// Defaults to blue (`0xFF0000FF`).
  final int ledColor;

  /// LED on duration in milliseconds (Android).
  final int ledOnMs;

  /// LED off duration in milliseconds (Android).
  final int ledOffMs;

  // ---------------------------------------------------------------------------
  // Android — priority & icons
  // ---------------------------------------------------------------------------

  /// Notification priority (Android).
  ///
  /// Use constants from [Priority] (e.g. `Priority.high`). Mapped to an int
  /// for serialisation. Defaults to high priority (`1`).
  final int priority;

  /// Whether to automatically dismiss the notification when the user taps it
  /// (Android).
  final bool autoCancel;

  /// Android notification small icon resource name.
  ///
  /// Defaults to `'@mipmap/ic_launcher'`.
  final String smallIconRes;

  /// Android notification group key.
  ///
  /// Used when [groupMessages] is `true`.
  final String groupKey;

  // ---------------------------------------------------------------------------
  // iOS — category
  // ---------------------------------------------------------------------------

  /// UNNotification category identifier (iOS).
  ///
  /// Used to associate notifications with registered notification categories
  /// and their actions.
  final String categoryIdentifier;

  // ---------------------------------------------------------------------------
  // Custom extras
  // ---------------------------------------------------------------------------

  /// Arbitrary key-value data attached to every notification payload.
  final Map<String, String> customExtras;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  const YourGPTNotificationConfig({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.soundName,
    this.badgeEnabled = true,
    this.vibrationEnabled = true,
    this.vibrationPattern,
    this.groupMessages = true,
    this.threadIdentifierPrefix = 'com.yourgpt.sdk',
    this.autoDismissOnOpen = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
    this.showMessagePreview = true,
    this.maxPreviewLength = 100,
    this.showReplyAction = true,
    this.stackNotifications = true,
    this.maxNotificationStack = 5,
    this.channelId = 'yourgpt_messages',
    this.channelName = 'YourGPT Messages',
    this.channelDescription = 'Chat messages from YourGPT AI assistant',
    this.ledEnabled = true,
    this.ledColor = 0xFF0000FF,
    this.ledOnMs = 300,
    this.ledOffMs = 3000,
    this.priority = 1,
    this.autoCancel = true,
    this.smallIconRes = '@mipmap/ic_launcher',
    this.groupKey = 'com.yourgpt.sdk.MESSAGES',
    this.categoryIdentifier = 'chat_message',
    this.customExtras = const {},
  });

  // ---------------------------------------------------------------------------
  // Utility helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` if the current local time falls within the configured
  /// quiet hours window (including overnight ranges).
  bool isInQuietHours() {
    if (!quietHoursEnabled) return false;

    final now = DateTime.now().hour;

    if (quietHoursStart <= quietHoursEnd) {
      // Same-day range, e.g. 09:00–17:00
      return now >= quietHoursStart && now < quietHoursEnd;
    } else {
      // Overnight range, e.g. 22:00–08:00
      return now >= quietHoursStart || now < quietHoursEnd;
    }
  }

  /// Returns `true` when a notification should be shown given the current
  /// state of [notificationsEnabled] and quiet hours.
  bool shouldShowNotification() {
    if (!notificationsEnabled) return false;
    if (isInQuietHours()) return false;
    return true;
  }

  /// Truncates [message] to [maxPreviewLength] characters (appending "…") if
  /// [showMessagePreview] is enabled.
  ///
  /// Returns an empty string when [showMessagePreview] is `false`.
  String processedMessageContent(String message) {
    if (!showMessagePreview) return '';
    if (message.length <= maxPreviewLength) return message;
    return '${message.substring(0, maxPreviewLength)}…';
  }

  /// Returns the thread / group identifier for [sessionUid].
  String threadIdentifier(String? sessionUid) {
    if (sessionUid == null || sessionUid.isEmpty) return threadIdentifierPrefix;
    return '$threadIdentifierPrefix.$sessionUid';
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  YourGPTNotificationConfig copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    String? soundName,
    bool? badgeEnabled,
    bool? vibrationEnabled,
    List<int>? vibrationPattern,
    bool? groupMessages,
    String? threadIdentifierPrefix,
    bool? autoDismissOnOpen,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? showMessagePreview,
    int? maxPreviewLength,
    bool? showReplyAction,
    bool? stackNotifications,
    int? maxNotificationStack,
    String? channelId,
    String? channelName,
    String? channelDescription,
    bool? ledEnabled,
    int? ledColor,
    int? ledOnMs,
    int? ledOffMs,
    int? priority,
    bool? autoCancel,
    String? smallIconRes,
    String? groupKey,
    String? categoryIdentifier,
    Map<String, String>? customExtras,
  }) {
    return YourGPTNotificationConfig(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundName: soundName ?? this.soundName,
      badgeEnabled: badgeEnabled ?? this.badgeEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      groupMessages: groupMessages ?? this.groupMessages,
      threadIdentifierPrefix:
          threadIdentifierPrefix ?? this.threadIdentifierPrefix,
      autoDismissOnOpen: autoDismissOnOpen ?? this.autoDismissOnOpen,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      showMessagePreview: showMessagePreview ?? this.showMessagePreview,
      maxPreviewLength: maxPreviewLength ?? this.maxPreviewLength,
      showReplyAction: showReplyAction ?? this.showReplyAction,
      stackNotifications: stackNotifications ?? this.stackNotifications,
      maxNotificationStack: maxNotificationStack ?? this.maxNotificationStack,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelDescription: channelDescription ?? this.channelDescription,
      ledEnabled: ledEnabled ?? this.ledEnabled,
      ledColor: ledColor ?? this.ledColor,
      ledOnMs: ledOnMs ?? this.ledOnMs,
      ledOffMs: ledOffMs ?? this.ledOffMs,
      priority: priority ?? this.priority,
      autoCancel: autoCancel ?? this.autoCancel,
      smallIconRes: smallIconRes ?? this.smallIconRes,
      groupKey: groupKey ?? this.groupKey,
      categoryIdentifier: categoryIdentifier ?? this.categoryIdentifier,
      customExtras: customExtras ?? this.customExtras,
    );
  }
}
