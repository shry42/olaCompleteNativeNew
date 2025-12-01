import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      print('✅ NotificationService: Initialized successfully');
    } catch (e) {
      print('❌ NotificationService: Initialization failed: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 NotificationService: Notification tapped: ${response.payload}');
    // Handle notification tap if needed
  }

  /// Show stationary vehicle warning notification
  Future<void> showStationaryWarning({
    required String vehicleId,
    required String message,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'stationary_warning',
        'Stationary Vehicle Warning',
        channelDescription: 'Notifications for stationary vehicle warnings',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFE53E3E),
        playSound: true,
        enableVibration: true,
        ongoing: true,
        autoCancel: false,
        showWhen: true,
        when: null,
        usesChronometer: false,
        chronometerCountDown: false,
        actions: [
          AndroidNotificationAction(
            'stop_vehicle',
            'Stop Vehicle',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_stop'),
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'dismiss',
            'Dismiss',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_close'),
            showsUserInterface: false,
          ),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        threadIdentifier: 'stationary_warning',
        categoryIdentifier: 'stationary_warning',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1001, // Unique ID for stationary warning
        '🚨 Stationary Vehicle Alert',
        'Vehicle $vehicleId: $message',
        notificationDetails,
        payload: 'stationary_warning_$vehicleId',
      );

      print('✅ NotificationService: Stationary warning notification shown');
    } catch (e) {
      print('❌ NotificationService: Failed to show notification: $e');
    }
  }

  /// Show vehicle stopped notification
  Future<void> showVehicleStopped({
    required String vehicleId,
    required String message,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'vehicle_stopped',
        'Vehicle Stopped',
        channelDescription: 'Notifications when vehicle is stopped',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF4CAF50),
        playSound: true,
        enableVibration: true,
        ongoing: false,
        autoCancel: true,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        threadIdentifier: 'vehicle_stopped',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1002, // Unique ID for vehicle stopped
        '✅ Vehicle Stopped',
        'Vehicle $vehicleId: $message',
        notificationDetails,
        payload: 'vehicle_stopped_$vehicleId',
      );

      print('✅ NotificationService: Vehicle stopped notification shown');
    } catch (e) {
      print('❌ NotificationService: Failed to show vehicle stopped notification: $e');
    }
  }

  /// Cancel stationary warning notification
  Future<void> cancelStationaryWarning() async {
    try {
      await _notifications.cancel(1001);
      print('✅ NotificationService: Stationary warning notification cancelled');
    } catch (e) {
      print('❌ NotificationService: Failed to cancel notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('✅ NotificationService: All notifications cancelled');
    } catch (e) {
      print('❌ NotificationService: Failed to cancel all notifications: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ?? false;
    }
    return true; // iOS notifications are always enabled if permission is granted
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true; // iOS permissions are handled during initialization
  }
}
