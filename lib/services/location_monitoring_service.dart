import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationMonitoringService {
  static final LocationMonitoringService _instance = LocationMonitoringService._internal();
  factory LocationMonitoringService() => _instance;
  LocationMonitoringService._internal();

  // Notification management
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Monitoring timers
  Timer? _locationCheckTimer;
  Timer? _warningNotificationTimer;
  
  // State management
  bool _isLocationEnabled = true;
  bool _isMonitoring = false;
  int _warningCount = 0;
  DateTime? _lastWarningTime;
  
  // Callbacks
  Function(bool isLocationEnabled)? onLocationStatusChanged;
  Function(String message)? onLocationWarning;

  /// Initialize the location monitoring service
  Future<void> initialize() async {
    print('🔍 [LOCATION_MONITOR] Initializing LocationMonitoringService...');
    
    // Initialize notifications
    await _initializeNotifications();
    
    // Check initial location status
    await _checkLocationStatus();
    
    print('✅ [LOCATION_MONITOR] LocationMonitoringService initialized');
  }

  /// Initialize local notifications
  Future<void> _initializeNotifications() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Request notification permissions for Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Start monitoring location status
  void startMonitoring({Duration checkInterval = const Duration(seconds: 2)}) {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    print('🔍 [LOCATION_MONITOR] Starting location monitoring with ${checkInterval.inSeconds}s interval...');
    
    // Check location status with specified interval
    _locationCheckTimer = Timer.periodic(checkInterval, (timer) {
      _checkLocationStatus();
    });
  }

  /// Stop monitoring location status
  void stopMonitoring() {
    _isMonitoring = false;
    _locationCheckTimer?.cancel();
    _warningNotificationTimer?.cancel();
    _locationCheckTimer = null;
    _warningNotificationTimer = null;
    
    // Cancel all location warnings
    _cancelLocationWarnings();
    
    print('🔍 [LOCATION_MONITOR] Stopped location monitoring');
  }

  /// Check current location status
  Future<void> _checkLocationStatus() async {
    try {
      // Check if location services are enabled
      final bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      
      // Check location permissions
      final LocationPermission permission = await Geolocator.checkPermission();
      final bool hasPermission = permission != LocationPermission.denied && 
                                permission != LocationPermission.deniedForever;
      
      final bool locationAvailable = isLocationEnabled && hasPermission;
      
      if (_isLocationEnabled != locationAvailable) {
        _isLocationEnabled = locationAvailable;
        onLocationStatusChanged?.call(_isLocationEnabled);
        
        if (!_isLocationEnabled) {
          _handleLocationDisabled();
        } else {
          _handleLocationEnabled();
        }
      }
    } catch (e) {
      print('❌ [LOCATION_MONITOR] Error checking location status: $e');
    }
  }

  /// Handle location being disabled
  void _handleLocationDisabled() {
    print('🚨 [LOCATION_MONITOR] Location disabled - starting warnings');
    _warningCount = 0;
    _lastWarningTime = DateTime.now();
    
    // Show immediate warning
    _showLocationWarning();
    
    // Start frequent warning notifications
    _startFrequentWarnings();
    
    // Notify callback
    onLocationWarning?.call('Location services are disabled! Please enable location immediately.');
  }

  /// Handle location being enabled
  void _handleLocationEnabled() {
    print('✅ [LOCATION_MONITOR] Location enabled - stopping warnings');
    
    // Stop warning notifications
    _stopFrequentWarnings();
    
    // Cancel all warnings
    _cancelLocationWarnings();
    
    // Reset warning count
    _warningCount = 0;
  }

  /// Start frequent warning notifications
  void _startFrequentWarnings() {
    _stopFrequentWarnings(); // Stop any existing warnings
    
    // Show warning every 10 seconds
    _warningNotificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _showLocationWarning();
    });
  }

  /// Stop frequent warning notifications
  void _stopFrequentWarnings() {
    _warningNotificationTimer?.cancel();
    _warningNotificationTimer = null;
  }

  /// Show location warning notification
  Future<void> _showLocationWarning() async {
    _warningCount++;
    
    // Create high-priority notification
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'mfb_location_warning',
      'MFB Location Warning',
      channelDescription: 'Critical warnings about location services being disabled',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFE53E3E),
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.critical,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      2001, // Fixed ID for location warning
      '🚨 CRITICAL: Location Disabled!',
      'MFB Field tracking requires location services. Enable location immediately! (Warning #$_warningCount)',
      platformChannelSpecifics,
    );
    
    print('🚨 [LOCATION_MONITOR] Location warning notification #$_warningCount sent');
  }

  /// Cancel all location warning notifications
  Future<void> _cancelLocationWarnings() async {
    await _localNotifications.cancel(2001);
    print('🔇 [LOCATION_MONITOR] Location warning notifications cancelled');
  }

  /// Show in-app location warning dialog
  void showLocationWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button
          child: AlertDialog(
            backgroundColor: const Color(0xFFE53E3E),
            title: const Row(
              children: [
                Icon(Icons.location_off, color: Colors.white, size: 30),
                SizedBox(width: 10),
                Text(
                  'CRITICAL WARNING',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Location services are disabled!\n\n'
              'MFB Field tracking requires location to be enabled at all times for emergency response.\n\n'
              'Please enable location services immediately.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  // Open location settings
                  await Geolocator.openLocationSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFE53E3E),
                ),
                child: const Text(
                  'OPEN LOCATION SETTINGS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  // Check location again
                  await _checkLocationStatus();
                  if (_isLocationEnabled) {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'CHECK AGAIN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Force check location status
  Future<bool> forceCheckLocation() async {
    await _checkLocationStatus();
    return _isLocationEnabled;
  }

  /// Trigger immediate location check (useful when app resumes)
  Future<void> triggerImmediateCheck() async {
    print('🔍 [LOCATION_MONITOR] Triggering immediate location check...');
    await _checkLocationStatus();
  }

  /// Get current location status
  bool get isLocationEnabled => _isLocationEnabled;
  
  /// Get warning count
  int get warningCount => _warningCount;
  
  /// Get last warning time
  DateTime? get lastWarningTime => _lastWarningTime;

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission != LocationPermission.denied && 
           permission != LocationPermission.deniedForever;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission != LocationPermission.denied && 
           permission != LocationPermission.deniedForever;
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    print('🔍 [LOCATION_MONITOR] LocationMonitoringService disposed');
  }
}
