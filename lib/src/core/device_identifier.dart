import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

/// Resolves a 100% persistent device identifier and device hardware metadata
class DeviceIdentifier {
  static String? _cachedDeviceId;
  static Map<String, dynamic>? _cachedDeviceInfo;

  /// Get or initialize consistent device id
  static Future<String> getDeviceId({String? persistedId, Function(String)? onSaveId}) async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    // 1. Check if an ID was previously persisted in local storage
    if (persistedId != null && persistedId.trim().isNotEmpty) {
      _cachedDeviceId = persistedId.trim();
      return _cachedDeviceId!;
    }

    // 2. Try hardware identifier resolution
    String resolvedId = '';
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final android = await deviceInfo.androidInfo;
          resolvedId = android.id;
        } else if (Platform.isIOS) {
          final ios = await deviceInfo.iosInfo;
          resolvedId = ios.identifierForVendor ?? '';
        } else if (Platform.isMacOS) {
          final mac = await deviceInfo.macOsInfo;
          resolvedId = mac.systemGUID ?? '';
        } else if (Platform.isWindows) {
          final win = await deviceInfo.windowsInfo;
          resolvedId = win.deviceId;
        } else if (Platform.isLinux) {
          final linux = await deviceInfo.linuxInfo;
          resolvedId = linux.machineId ?? '';
        }
      }
    } catch (_) {
      // Ignored - fallback below
    }

    // 3. Guaranteed UUID fallback if hardware ID is empty/unknown
    if (resolvedId.trim().isEmpty || resolvedId == 'unknown' || resolvedId.length < 4) {
      resolvedId = 'dev_${const Uuid().v4()}';
    }

    _cachedDeviceId = resolvedId;
    if (onSaveId != null) {
      onSaveId(resolvedId);
    }
    return resolvedId;
  }

  /// Collect rich device metadata (OS, model, app version, screen specs)
  static Future<Map<String, dynamic>> collectDeviceInfo() async {
    if (_cachedDeviceInfo != null) return _cachedDeviceInfo!;

    String os = 'unknown';
    String osVersion = '';
    String model = '';
    String brand = '';
    String appVersion = '';
    String buildNumber = '';

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    } catch (_) {}

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        os = 'web';
        final web = await deviceInfo.webBrowserInfo;
        model = web.browserName.name;
        osVersion = web.userAgent ?? '';
      } else if (Platform.isAndroid) {
        os = 'android';
        final android = await deviceInfo.androidInfo;
        brand = android.brand;
        model = android.model;
        osVersion = 'Android ${android.version.release} (SDK ${android.version.sdkInt})';
      } else if (Platform.isIOS) {
        os = 'ios';
        final ios = await deviceInfo.iosInfo;
        brand = 'Apple';
        model = ios.utsname.machine;
        osVersion = 'iOS ${ios.systemVersion}';
      } else if (Platform.isMacOS) {
        os = 'macos';
        final mac = await deviceInfo.macOsInfo;
        brand = 'Apple';
        model = mac.model;
        osVersion = 'macOS ${mac.osRelease}';
      } else if (Platform.isWindows) {
        os = 'windows';
        final win = await deviceInfo.windowsInfo;
        brand = win.registeredOwner;
        model = win.productName;
        osVersion = '${win.majorVersion}.${win.minorVersion}';
      } else if (Platform.isLinux) {
        os = 'linux';
        final linux = await deviceInfo.linuxInfo;
        model = linux.name;
        osVersion = linux.versionId ?? '';
      }
    } catch (_) {}

    _cachedDeviceInfo = {
      'os': os,
      'osVersion': osVersion,
      'deviceModel': model,
      'deviceBrand': brand,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
    };

    return _cachedDeviceInfo!;
  }
}
