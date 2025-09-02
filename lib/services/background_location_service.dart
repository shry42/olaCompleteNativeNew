import 'dart:async';
import 'dart:convert';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class BackgroundLocationService extends TaskHandler {
  static const String _apiUrl = 'http://115.242.59.130:9000/api/Common/CommonAPI';
  static String _vehicleId = 'ALP4';
  static int _updateCounter = 0;
  
  static void setVehicleId(String vehicleId) {
    _vehicleId = vehicleId.isEmpty ? 'ALP4' : vehicleId;
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('🟢 Background location service started');
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Calculate real speed from GPS (convert m/s to km/h)
      final double realSpeed = position.speed * 3.6;
      final int speedKmh = realSpeed.isNaN || realSpeed < 0 ? 0 : realSpeed.round();
      
      // Generate dynamic device info
      final deviceInfo = await _getDeviceInfo();
        
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
        
      print('📤 [BACKGROUND] Sending GPS update #${_updateCounter + 1}: Lat: ${position.latitude}, Lng: ${position.longitude}, Speed: ${speedKmh} km/h');
        
      // Make API call
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
        
      if (response.statusCode == 200) {
        _updateCounter++;
        print('✅ [BACKGROUND] Location update #${_updateCounter} sent successfully');
        
        // Update foreground task notification
        FlutterForegroundTask.updateService(
          notificationTitle: '🚒 Mumbai Fire Brigade Tracking',
          notificationText: '📍 Update #${_updateCounter} • Speed: ${speedKmh} km/h • ID: ${_vehicleId}',
        );
      } else {
        print('❌ [BACKGROUND] API call failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [BACKGROUND] Error sending location update: $e');
    }
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final DateTime now = DateTime.now();
    final random = (now.millisecondsSinceEpoch % 100);
    
    // Simulate different device states based on time
    final isCharging = random < 20;
    final batteryLevel = isCharging ? 
        (70 + (random % 30)) : 
        (30 + (random % 60));
    
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
