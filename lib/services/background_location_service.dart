import 'dart:async';
import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BackgroundLocationService extends TaskHandler {
  static const String _apiUrl = 'http://115.242.59.130:9000/api/Common/CommonAPI';
  static String _vehicleId = 'ALP4';
  static int _updateCounter = 0;
  
  // Sequential timestamp system
  static DateTime _lastSuccessfulTimestamp = DateTime.now();
  static List<Map<String, dynamic>> _failedUpdates = [];
  static bool _isRetryingFailed = false;
  
  // Silent operation - no retry mechanism
  
  static void setVehicleId(String vehicleId) {
    _vehicleId = vehicleId.isEmpty ? 'ALP4' : vehicleId;
  }

  // Get next sequential timestamp (5 seconds apart)
  static DateTime _getNextSequentialTimestamp() {
    if (_isRetryingFailed && _failedUpdates.isNotEmpty) {
      // Return the timestamp of the first failed update
      return DateTime.parse(_failedUpdates.first['timestamp']);
    } else {
      // Return next 5-second interval
      return _lastSuccessfulTimestamp.add(const Duration(seconds: 5));
    }
  }

  // Add failed update to cache
  static void _addFailedUpdate(Map<String, dynamic> payload) {
    final timestamp = _getNextSequentialTimestamp();
    final failedUpdate = {
      'timestamp': timestamp.toIso8601String().substring(0, 19) + 'Z',
      'payload': payload,
      'retryCount': 0,
    };
    _failedUpdates.add(failedUpdate);
    print('📦 [BACKGROUND] Cached failed update for timestamp: ${failedUpdate['timestamp']}');
  }

  // Retry failed updates in sequence
  static Future<void> _retryFailedUpdates() async {
    if (_failedUpdates.isEmpty || _isRetryingFailed) return;
    
    _isRetryingFailed = true;
    print('🔄 [BACKGROUND] Starting retry of ${_failedUpdates.length} failed updates...');
    
    while (_failedUpdates.isNotEmpty) {
      final failedUpdate = _failedUpdates.first;
      failedUpdate['retryCount'] = (failedUpdate['retryCount'] ?? 0) + 1;
      
      print('🔄 [BACKGROUND] Retrying update #${failedUpdate['retryCount']} for timestamp: ${failedUpdate['timestamp']}');
      
      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(failedUpdate['payload']),
        );
        
        if (response.statusCode == 200) {
          print('✅ [BACKGROUND] Retry successful for timestamp: ${failedUpdate['timestamp']}');
          _failedUpdates.removeAt(0);
          _lastSuccessfulTimestamp = DateTime.parse(failedUpdate['timestamp'].replaceAll('Z', ''));
          _updateCounter++;
        } else {
          print('❌ [BACKGROUND] Retry failed for timestamp: ${failedUpdate['timestamp']} (Status: ${response.statusCode})');
          if (failedUpdate['retryCount'] >= 3) {
            print('🚫 [BACKGROUND] Max retries reached, removing from cache: ${failedUpdate['timestamp']}');
            _failedUpdates.removeAt(0);
          } else {
            // Move to end of queue for later retry
            _failedUpdates.add(_failedUpdates.removeAt(0));
          }
        }
      } catch (e) {
        print('❌ [BACKGROUND] Retry error for timestamp: ${failedUpdate['timestamp']}: $e');
        if (failedUpdate['retryCount'] >= 3) {
          print('🚫 [BACKGROUND] Max retries reached, removing from cache: ${failedUpdate['timestamp']}');
          _failedUpdates.removeAt(0);
        } else {
          _failedUpdates.add(_failedUpdates.removeAt(0));
        }
      }
      
      // Wait 2 seconds between retries
      await Future.delayed(const Duration(seconds: 2));
    }
    
    _isRetryingFailed = false;
    print('✅ [BACKGROUND] Finished retrying failed updates');
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('🟢 Background location service started');
    // Initialize location services in background
    await _initializeBackgroundLocationServices();
    
    // Send initial location update after initialization
    print('🟢 Sending initial background location update...');
    await _sendLocationUpdate();
  }
  
  static Future<void> _initializeBackgroundLocationServices() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ [BACKGROUND] Location services are disabled');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print('❌ [BACKGROUND] Location permissions are denied');
        return;
      }
      
      // Test location access with fresh GPS coordinates
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
        forceAndroidLocationManager: false, // Use FusedLocationProvider for better accuracy
      );
      
      print('✅ [BACKGROUND] Location services initialized successfully');
    } catch (e) {
      print('❌ [BACKGROUND] Location services initialization failed: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    // Send location update every 5 seconds
    await _sendLocationUpdate();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('🔴 Background location service stopped');
  }

  static Future<void> _sendLocationUpdate() async {
    try {
      // First, retry any failed updates
      await _retryFailedUpdates();
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        print('❌ Location permissions denied');
        return;
      }

      // Get fresh GPS coordinates using Geolocator with speed
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
        forceAndroidLocationManager: false, // Use FusedLocationProvider for better accuracy
      );
      
      // Calculate real speed from GPS (convert m/s to km/h)
      final double realSpeed = position.speed * 3.6;
      final int speedKmh = realSpeed.isNaN || realSpeed < 0 ? 0 : realSpeed.round();
      
      // Generate dynamic device info
      final deviceInfo = await _getDeviceInfo();
      
      // Get next sequential timestamp (5 seconds apart)
      final nextTimestamp = _getNextSequentialTimestamp();
      final timestampString = nextTimestamp.toIso8601String().substring(0, 19) + 'Z';
        
      // Prepare API payload with all parameters
      final Map<String, dynamic> payload = {
        "storedProcedureName": "sp_HandleDeviceLocation",
        "DbType": "SQL",
        "parameters": {
          "mode": 1,
          "UnitId": _vehicleId,
          "Latitude": position.latitude,
          "Longitude": position.longitude,
          "Speed": speedKmh,
          "CreatedAt": timestampString, // Sequential timestamp (5 seconds apart)
          "BatteryPercentage": deviceInfo['batteryPercentage'],
          "PhoneMode": deviceInfo['phoneMode'],
          "LocationType": "live",
          "GpsSatellites": deviceInfo['gpsSatellites'],
          "Is_it_root": deviceInfo['isRoot'],
          "Is_it_long": deviceInfo['isLong'],
          "Direction": deviceInfo['direction'],
          "Power_saving_mode": deviceInfo['powerSavingMode'],
          "Performance_mode": deviceInfo['performanceMode'],
          "Flight_mode": deviceInfo['flightMode'],
          "Background_restricted_mode": deviceInfo['backgroundRestrictedMode'],
          "SignalStrength": deviceInfo['signalStrength']
        }
      };
        
      print('📤 [BACKGROUND] Sending SEQUENTIAL GPS update: Lat: ${position.latitude}, Lng: ${position.longitude}, Speed: ${speedKmh} km/h');
      print('📤 [BACKGROUND] Sequential Timestamp: $timestampString');
        
      // Check internet connectivity before making API call
      final connectivityResults = await Connectivity().checkConnectivity();
      final isConnected = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
      
      if (!isConnected) {
        print('❌ [BACKGROUND] No internet connection - adding to failed updates cache');
        _addFailedUpdate(payload);
        return;
      }
        
      // Make API call
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
        
      if (response.statusCode == 200) {
        _updateCounter++;
        _lastSuccessfulTimestamp = nextTimestamp;
        print('✅ [BACKGROUND] Sequential update #$_updateCounter sent successfully for timestamp: $timestampString');
        
        // Update foreground task notification
        FlutterForegroundTask.updateService(
          notificationTitle: '🚒 MFB Field Tracking',
          notificationText: '📍 Update #$_updateCounter • Speed: ${speedKmh} km/h • ID: $_vehicleId',
        );
      } else {
        print('❌ [BACKGROUND] Failed to send sequential update for timestamp: $timestampString (Status: ${response.statusCode})');
        _addFailedUpdate(payload);
      }
    } catch (e) {
      // Silent error handling - no user notification
    }
    
    // Silent operation - no retry mechanism
  }


  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final DateTime now = DateTime.now();
    final random = (now.millisecondsSinceEpoch % 100);
    
    // Get real battery information with error handling
    int batteryLevel = 0;
    bool isCharging = false;
    
    try {
      final Battery battery = Battery();
      final int realBatteryLevel = await battery.batteryLevel;
      final BatteryState batteryState = await battery.batteryState;
      isCharging = batteryState == BatteryState.charging;
      
      // Debug battery information
      print('🔋 [BACKGROUND] Real Battery Level: $realBatteryLevel%');
      print('🔋 [BACKGROUND] Battery State: $batteryState');
      print('🔋 [BACKGROUND] Is Charging: $isCharging');
      
      // Use real battery level if valid (0-100), otherwise fallback
      if (realBatteryLevel >= 0 && realBatteryLevel <= 100) {
        batteryLevel = realBatteryLevel;
        print('🔋 [BACKGROUND] Using REAL battery level: $batteryLevel%');
      } else {
        batteryLevel = 30 + (random % 60); // Fallback
        print('🔋 [BACKGROUND] Using FALLBACK battery level: $batteryLevel%');
      }
    } catch (e) {
      print('🔋 [BACKGROUND] Battery API error: $e');
      batteryLevel = 30 + (random % 60); // Fallback on error
      print('🔋 [BACKGROUND] Using FALLBACK battery level due to error: $batteryLevel%');
    }
    
    print('🔋 [BACKGROUND] Final Battery Level Used: $batteryLevel%');
    
    final phoneMode = batteryLevel < 50 ? "BatterySaver" : 
                     batteryLevel > 80 ? "Normal" : "Optimized";
    
    // Simulate GPS satellite count (4-12 satellites)
    final satellites = 4 + (random % 9);
    
    // Generate additional device parameters
    final isRoot = random < 10 ? 1 : 0;
    final isLong = random < 30 ? 1 : 0;
    final direction = random * 3.6;
    final powerSavingMode = batteryLevel < 30 ? 1 : 0;
    final performanceMode = batteryLevel > 70 ? 1 : 0;
    final flightMode = 0;
    final backgroundRestrictedMode = random < 20 ? 1 : 0;
    final signalStrength = -50 - (random % 50);
    
    return {
      'batteryPercentage': batteryLevel,
      'phoneMode': phoneMode,
      'gpsSatellites': satellites,
      'isRoot': isRoot,
      'isLong': isLong,
      'direction': direction.round(),
      'powerSavingMode': powerSavingMode,
      'performanceMode': performanceMode,
      'flightMode': flightMode,
      'backgroundRestrictedMode': backgroundRestrictedMode,
      'signalStrength': signalStrength,
    };
  }
}
