import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;
  bool _isAppInBackground = false;
  
  // Callbacks
  Function(bool isConnected)? onConnectivityChanged;

  Future<void> initialize() async {
    // Initialize local notifications
    await _initializeNotifications();
    
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

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

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    print('🌐 Connectivity changed: $_isConnected (was: $wasConnected)');
    
    // Only trigger callbacks if status actually changed
    if (wasConnected != _isConnected) {
      onConnectivityChanged?.call(_isConnected);
      
      if (!_isConnected) {
        _handleNoInternet();
      } else {
        _handleInternetRestored();
      }
    }
  }

  void _handleNoInternet() {
    print('❌ No internet connection detected');
    
    // Show notification if app is in background or locked
    if (_isAppInBackground) {
      _showNoInternetNotification();
    }
  }

  void _handleInternetRestored() {
    print('✅ Internet connection restored');
    
    // Cancel any existing no internet notifications
    _cancelNoInternetNotification();
  }

  Future<void> _showNoInternetNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'mfb_field_connectivity',
      'MFB Field Connectivity',
      channelDescription: 'Notifications about internet connectivity status',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFE53E3E),
      ongoing: true, // Make it persistent
      autoCancel: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      1001, // Fixed ID for no internet notification
      '🚫 No Internet Connection',
      'MFB Field tracking paused. Location updates will resume when connection is restored.',
      platformChannelSpecifics,
    );
  }

  Future<void> _cancelNoInternetNotification() async {
    await _localNotifications.cancel(1001);
  }

  void setAppState({required bool isInBackground}) {
    _isAppInBackground = isInBackground;
    print('📱 App state changed: ${isInBackground ? 'Background' : 'Foreground'}');
    
    // If app goes to background and no internet, show notification
    if (isInBackground && !_isConnected) {
      _showNoInternetNotification();
    }
    // If app comes to foreground, cancel notification
    else if (!isInBackground) {
      _cancelNoInternetNotification();
    }
  }

  bool get isConnected => _isConnected;

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
