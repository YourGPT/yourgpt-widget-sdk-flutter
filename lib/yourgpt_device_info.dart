import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Collects device and application metadata for automatic visitor enrichment.
///
/// Mirrors the auto-enrichment behaviour of the Android and iOS SDKs:
/// when [setVisitorData] is called on a chat screen, these fields are merged
/// into the payload before it is sent to the widget — developers do not need
/// to supply them manually.
class YourGPTDeviceInfo {
  YourGPTDeviceInfo._();

  /// Returns a map of device and app metadata for the current platform.
  ///
  /// Keys returned:
  /// - `platform`      — "Android", "iOS", "Web", "macOS", "Windows", "Linux"
  /// - `deviceModel`   — hardware model string (e.g. "Pixel 6", "iPhone 15")
  /// - `systemVersion` — OS version string (e.g. "Android 14", "iOS 17.2")
  /// - `appVersion`    — app version from pubspec (e.g. "2.3.1")
  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return {
          'platform': 'Web',
          'deviceModel': webInfo.browserName.name,
          'systemVersion': webInfo.platform ?? 'Web',
          'appVersion': appVersion,
        };
      }

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'deviceModel': androidInfo.model,
          'systemVersion': 'Android ${androidInfo.version.release}',
          'appVersion': appVersion,
        };
      }

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'deviceModel': iosInfo.utsname.machine,
          'systemVersion': 'iOS ${iosInfo.systemVersion}',
          'appVersion': appVersion,
        };
      }

      if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return {
          'platform': 'macOS',
          'deviceModel': macInfo.model,
          'systemVersion': 'macOS ${macInfo.osRelease}',
          'appVersion': appVersion,
        };
      }

      if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        return {
          'platform': 'Windows',
          'deviceModel': winInfo.computerName,
          'systemVersion': 'Windows ${winInfo.majorVersion}',
          'appVersion': appVersion,
        };
      }

      if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return {
          'platform': 'Linux',
          'deviceModel': linuxInfo.name,
          'systemVersion': linuxInfo.version ?? 'Linux',
          'appVersion': appVersion,
        };
      }
    } catch (_) {
      // Gracefully degrade — return a minimal map rather than crashing.
    }

    return {
      'platform': 'Flutter',
      'deviceModel': 'Unknown',
      'systemVersion': 'Unknown',
      'appVersion': appVersion,
    };
  }
}
