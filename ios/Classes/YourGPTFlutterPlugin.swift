import Flutter
import UIKit
import UserNotifications

/// Flutter plugin that provides native APNs push notification support.
///
/// Handles:
/// - APNs device token acquisition via `registerForRemoteNotifications()`
/// - Notification permission requests
/// - Foreground notification display (minimalist mode)
/// - Notification tap handling
///
/// Communicates with Dart via MethodChannel `com.yourgpt.sdk/apns`.
public class YourGPTFlutterPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {

    // MARK: - Properties

    private var channel: FlutterMethodChannel?
    private var cachedToken: String?

    private static let tokenKey = "yourgpt_apns_token"

    // MARK: - Plugin Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.yourgpt.sdk/apns",
            binaryMessenger: registrar.messenger()
        )
        let instance = YourGPTFlutterPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)

        // Restore cached token from UserDefaults
        instance.cachedToken = UserDefaults.standard.string(forKey: tokenKey)

        // Set ourselves as the notification center delegate for foreground handling.
        // Deferred to next run loop iteration so all auto-registered plugins
        // (including firebase_messaging) finish registration first.
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().delegate = instance
        }
    }

    // MARK: - MethodChannel Handler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestPermission":
            requestPermission(result: result)
        case "getToken":
            result(cachedToken)
        case "isPermissionGranted":
            checkPermission(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Permission

    private func requestPermission(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self?.channel?.invokeMethod(
                    granted ? "onPermissionGranted" : "onPermissionDenied",
                    arguments: nil
                )
                result(granted)
            }
        }
    }

    private func checkPermission(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                result(settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - APNs Token (UIApplicationDelegate)

    public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        cachedToken = token

        // Persist to UserDefaults
        UserDefaults.standard.set(token, forKey: Self.tokenKey)

        // Send to Dart
        channel?.invokeMethod("onTokenReceived", arguments: token)
    }

    public func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        channel?.invokeMethod("onTokenError", arguments: error.localizedDescription)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Foreground notification display — show banner with sound and badge.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let data = serializeUserInfo(userInfo)

        // Notify Dart about incoming notification
        channel?.invokeMethod("onNotificationReceived", arguments: data)

        // Show the notification banner in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    /// Notification tap handler — notify Dart so it can open the relevant chat.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let data = serializeUserInfo(userInfo)

        channel?.invokeMethod("onNotificationTapped", arguments: data)
        completionHandler()
    }

    // MARK: - Helpers

    private func serializeUserInfo(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
        var result = [String: Any]()
        for (key, value) in userInfo {
            if let stringKey = key as? String {
                result[stringKey] = value
            }
        }
        return result
    }
}
