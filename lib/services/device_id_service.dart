import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  static String? _cachedDeviceId;
  static const String _deviceIdKey = 'cached_device_id';

  /// Get unique device identifier
  /// Returns a unique identifier for the device that persists across app reinstalls
  static Future<String> getDeviceId() async {
    // Return cached ID if available
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String? deviceId;

      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        // Use Android ID - unique per device, survives factory reset
        deviceId = androidInfo.id;
        print('📱 Android Device ID: $deviceId');
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        // Use identifierForVendor - unique per app installation
        deviceId = iosInfo.identifierForVendor;
        print('📱 iOS Device ID: $deviceId');
      } else if (Platform.isWindows) {
        final WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        // Use Windows machine GUID
        deviceId = windowsInfo.deviceId;
        print('📱 Windows Device ID: $deviceId');
      } else if (Platform.isMacOS) {
        final MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
        // Use macOS system UUID
        deviceId = macInfo.systemGUID;
        print('📱 macOS Device ID: $deviceId');
      } else if (Platform.isLinux) {
        final LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        // Use Linux machine ID
        deviceId = linuxInfo.machineId;
        print('📱 Linux Device ID: $deviceId');
      }

      // Fallback to generated UUID if device info is not available
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = _generateFallbackId();
        print('📱 Generated Fallback Device ID: $deviceId');
      }

      // Cache the device ID
      _cachedDeviceId = deviceId;
      
      // Store in SharedPreferences for persistence
      await _cacheDeviceId(deviceId);
      
      return deviceId;
    } catch (e) {
      print('❌ Error getting device ID: $e');
      // Return fallback ID
      final fallbackId = _generateFallbackId();
      _cachedDeviceId = fallbackId;
      await _cacheDeviceId(fallbackId);
      return fallbackId;
    }
  }

  /// Generate a fallback device ID using timestamp and random number
  static String _generateFallbackId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString().padLeft(6, '0');
    return 'fallback_${timestamp}_$random';
  }

  /// Cache device ID in SharedPreferences
  static Future<void> _cacheDeviceId(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deviceIdKey, deviceId);
      print('💾 Device ID cached: $deviceId');
    } catch (e) {
      print('❌ Error caching device ID: $e');
    }
  }

  /// Load cached device ID from SharedPreferences
  static Future<String?> _loadCachedDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_deviceIdKey);
    } catch (e) {
      print('❌ Error loading cached device ID: $e');
      return null;
    }
  }

  /// Initialize device ID service - call this at app startup
  static Future<void> initialize() async {
    try {
      // Try to load cached device ID first
      final cachedId = await _loadCachedDeviceId();
      if (cachedId != null && cachedId.isNotEmpty) {
        _cachedDeviceId = cachedId;
        print('📱 Loaded cached Device ID: $cachedId');
        return;
      }

      // If no cached ID, get fresh device ID
      await getDeviceId();
    } catch (e) {
      print('❌ Error initializing device ID service: $e');
      // Set fallback ID
      _cachedDeviceId = _generateFallbackId();
    }
  }

  /// Get device info for debugging
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final Map<String, dynamic> info = {};

      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        info['platform'] = 'Android';
        info['model'] = androidInfo.model;
        info['brand'] = androidInfo.brand;
        info['device'] = androidInfo.device;
        info['androidId'] = androidInfo.id;
        info['version'] = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        info['platform'] = 'iOS';
        info['model'] = iosInfo.model;
        info['name'] = iosInfo.name;
        info['systemName'] = iosInfo.systemName;
        info['systemVersion'] = iosInfo.systemVersion;
        info['identifierForVendor'] = iosInfo.identifierForVendor;
      }

      return info;
    } catch (e) {
      print('❌ Error getting device info: $e');
      return {'error': e.toString()};
    }
  }
}
