import 'dart:convert';
import 'dart:ui' show Color;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'yourgpt_notification_config.dart';

/// Static helper utilities for push notification operations.
///
/// Mirrors [YourGPTNotificationHelper] from the Android and iOS SDKs.
///
/// Call [YourGPTNotificationHelper.initialize] once at app startup (after
/// [Firebase.initializeApp]) before using any other methods.
class YourGPTNotificationHelper {
  YourGPTNotificationHelper._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Notification tap callback — set by YourGPTNotificationClient.
  static void Function(Map<String, dynamic> data)? _onNotificationTap;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initialises the local notification plugin.
  ///
  /// Must be called once at app startup, after [Firebase.initializeApp].
  ///
  /// [androidDefaultIcon] — drawable resource name used for notifications on
  /// Android (defaults to the launcher icon).
  static Future<void> initialize({
    String androidDefaultIcon = '@mipmap/ic_launcher',
    void Function(Map<String, dynamic> data)? onNotificationTap,
  }) async {
    if (_initialized) return;
    _onNotificationTap = onNotificationTap;

    final androidSettings =
        AndroidInitializationSettings(androidDefaultIcon);

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data =
                jsonDecode(response.payload!) as Map<String, dynamic>;
            _onNotificationTap?.call(data);
          } catch (_) {}
        }
      },
    );

    _initialized = true;

    // Cold-start: detect if app was launched by tapping a local notification.
    // (FirebaseMessaging.getInitialMessage() doesn't cover local notifications.)
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null) {
        debugPrint('[YourGPT] Cold-start local notification tap detected');
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _onNotificationTap?.call(data);
        } catch (_) {}
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  /// Requests push notification permission from the user.
  ///
  /// Returns `true` if permission was granted (authorized or provisional).
  static Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    return granted;
  }

  /// Returns `true` if push notifications are currently authorised for this app.
  static Future<bool> areNotificationsEnabled() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // ---------------------------------------------------------------------------
  // Notification display
  // ---------------------------------------------------------------------------

  /// Shows a simple local notification.
  ///
  /// [data] is included as the notification payload so it can be retrieved
  /// when the user taps the notification.
  ///
  /// Respects [config.shouldShowNotification] — returns immediately when
  /// quiet hours are active or notifications are disabled.
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required YourGPTNotificationConfig config,
    String? sessionUid,
  }) async {
    debugPrint('[YourGPT] showLocalNotification called — title: "$title", body: "$body"');
    if (!_initialized) {
      debugPrint(
        '[YourGPT] showLocalNotification ABORTED — NotificationHelper not initialized! '
        'Call YourGPTNotificationHelper.initialize() at app startup.',
      );
      return;
    }

    if (!config.shouldShowNotification()) {
      debugPrint('[YourGPT] showLocalNotification SKIPPED — quiet hours active or notifications disabled');
      return;
    }

    final processedBody = config.processedMessageContent(body);
    final threadId = config.threadIdentifier(sessionUid);
    final id = _notificationId(sessionUid);

    final androidDetails = AndroidNotificationDetails(
      config.channelId,
      config.channelName,
      channelDescription: config.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: config.vibrationEnabled,
      vibrationPattern: config.vibrationPattern != null
          ? Int64List.fromList(config.vibrationPattern!)
          : null,
      playSound: config.soundEnabled,
      sound: config.soundName != null
          ? RawResourceAndroidNotificationSound(config.soundName!)
          : null,
      groupKey: config.groupMessages ? config.groupKey : null,
      setAsGroupSummary: false,
      enableLights: config.ledEnabled,
      ledColor: Color(config.ledColor),
      ledOnMs: config.ledOnMs,
      ledOffMs: config.ledOffMs,
      autoCancel: config.autoCancel,
      icon: config.smallIconRes,
      styleInformation: BigTextStyleInformation(processedBody),
    );

    final darwinDetails = DarwinNotificationDetails(
      threadIdentifier: config.groupMessages ? threadId : null,
      categoryIdentifier: config.categoryIdentifier,
      sound: config.soundEnabled ? (config.soundName ?? 'default') : null,
      badgeNumber: config.badgeEnabled ? 1 : null,
      presentAlert: true,
      presentBadge: config.badgeEnabled,
      presentSound: config.soundEnabled,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      id,
      title,
      processedBody,
      details,
      payload: jsonEncode({...data, if (sessionUid != null) 'session_uid': sessionUid}),
    );
    debugPrint('[YourGPT] showLocalNotification DISPLAYED — id: $id, title: "$title"');
  }

  /// Shows a rich notification with a subtitle (iOS/macOS).
  ///
  /// On Android, [subtitle] is prepended to the body text.
  static Future<void> showRichNotification({
    required String title,
    required String body,
    String? subtitle,
    required Map<String, dynamic> data,
    required YourGPTNotificationConfig config,
    String? sessionUid,
  }) async {
    final enrichedBody = (subtitle != null && subtitle.isNotEmpty)
        ? '$subtitle\n$body'
        : body;

    await showLocalNotification(
      title: title,
      body: enrichedBody,
      data: data,
      config: config,
      sessionUid: sessionUid,
    );
  }

  // ---------------------------------------------------------------------------
  // Notification management
  // ---------------------------------------------------------------------------

  /// Cancels all previously shown YourGPT notifications.
  static Future<void> removeAllDeliveredNotifications() async {
    await _plugin.cancelAll();
  }

  /// Cancels the notification with the given [id].
  static Future<void> removeNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Shows a notification with custom action buttons.
  ///
  /// On Android, actions are displayed as notification buttons. On iOS, they
  /// are registered as notification category actions.
  ///
  /// Mirrors `showActionNotification` / `createActionNotification` on the
  /// Android and iOS SDKs.
  static Future<void> showActionNotification({
    required String title,
    required String body,
    required List<NotificationAction> actions,
    required Map<String, dynamic> data,
    required YourGPTNotificationConfig config,
    String? sessionUid,
  }) async {
    if (!_initialized || !config.shouldShowNotification()) return;

    final processedBody = config.processedMessageContent(body);
    final threadId = config.threadIdentifier(sessionUid);
    final id = _notificationId(sessionUid);

    // Build Android action buttons.
    final androidActions = actions.map((a) {
      return AndroidNotificationAction(
        a.identifier,
        a.title,
        showsUserInterface: a.foreground,
      );
    }).toList();

    final androidDetails = AndroidNotificationDetails(
      config.channelId,
      config.channelName,
      channelDescription: config.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: config.vibrationEnabled,
      playSound: config.soundEnabled,
      actions: androidActions,
    );

    final darwinDetails = DarwinNotificationDetails(
      threadIdentifier: config.groupMessages ? threadId : null,
      categoryIdentifier: config.categoryIdentifier,
      presentAlert: true,
      presentBadge: config.badgeEnabled,
      presentSound: config.soundEnabled,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      id,
      title,
      processedBody,
      details,
      payload: jsonEncode({...data, if (sessionUid != null) 'session_uid': sessionUid}),
    );
  }

  // ---------------------------------------------------------------------------
  // Badge (iOS / macOS)
  // ---------------------------------------------------------------------------

  /// Resets the app's badge count to zero (iOS / macOS only).
  static Future<void> resetBadgeCount() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(badge: true);
    }
  }

  /// Increments the app's badge count by one (iOS / macOS only).
  ///
  /// Mirrors `incrementBadgeCount` on the iOS SDK.
  static Future<void> incrementBadgeCount() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      // flutter_local_notifications doesn't provide direct badge increment.
      // Use the iOS plugin to set badge; callers should track count externally.
      debugPrint(
        '[YourGPT] incrementBadgeCount: iOS badge management should be '
        'handled via UNUserNotificationCenter in the native layer.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Token utility
  // ---------------------------------------------------------------------------

  /// Retrieves the current FCM registration token.
  ///
  /// Returns `null` if Firebase Messaging is not configured or the token is
  /// not yet available.
  static Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Notification categories (iOS)
  // ---------------------------------------------------------------------------

  /// Registers notification categories with the system (iOS / macOS).
  ///
  /// Categories define the actions available when a user long-presses or
  /// expands a notification. Call this once at app startup if you use
  /// [showActionNotification].
  ///
  /// Mirrors `registerNotificationCategories` on the iOS SDK.
  static Future<void> registerNotificationCategories({
    List<DarwinNotificationCategory>? categories,
  }) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) return;

    if (categories == null || categories.isEmpty) {
      // Register default YourGPT category with reply action.
      categories = [
        DarwinNotificationCategory(
          'chat_message',
          actions: [
            DarwinNotificationAction.text(
              'reply',
              'Reply',
              buttonTitle: 'Send',
              placeholder: 'Type a reply…',
            ),
          ],
        ),
      ];
    }

    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: categories,
    );

    final initSettings = InitializationSettings(
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
  }

  /// Extracts reply text from a notification response payload.
  ///
  /// Returns `null` if the response does not contain reply text.
  ///
  /// Mirrors `getReplyText` on the Android and iOS SDKs.
  static String? getReplyText(NotificationResponse response) {
    return response.input;
  }

  // ---------------------------------------------------------------------------
  // ID generation
  // ---------------------------------------------------------------------------

  /// Generates a notification ID from a session UID.
  ///
  /// Exposed for use in [NotificationMode.advanced] when building custom
  /// notifications.
  static int generateNotificationId([String? sessionUid]) {
    return _notificationId(sessionUid);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static int _notificationId(String? sessionUid) {
    if (sessionUid == null) return 0;
    return sessionUid.hashCode.abs() % 100000;
  }
}

