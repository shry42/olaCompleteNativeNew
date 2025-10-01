import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'services/navigation_service.dart'; // Import your new service
import 'services/background_location_service.dart';
import 'services/connectivity_service.dart';
import 'services/device_id_service.dart';
import 'services/data_buffer_service.dart';
import 'services/location_monitoring_service.dart';
import 'screens/login_screen.dart'; // Import login screen

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize device ID service
  await DeviceIdService.initialize();
  
  // Initialize foreground task
    FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'mfb_field_tracking',
      channelName: 'MFB Field Location Tracking',
      channelDescription: 'This notification keeps the location tracking active for emergency response.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000), // 5 seconds
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MFB Field',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE53E3E)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE53E3E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53E3E),
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE53E3E),
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginScreen(), // Start with login screen
      debugShowCheckedModeBanner: false,
    );
  }
}

class NavigationScreen extends StatefulWidget {
  final String vehicleId;
  final String username;
  
  const NavigationScreen({super.key, required this.vehicleId, required this.username});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> with WidgetsBindingObserver {
  final NavigationService _navigationService = NavigationService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final DataBufferService _dataBuffer = DataBufferService();
  final LocationMonitoringService _locationMonitor = LocationMonitoringService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  bool _isMapReady = false;
  bool _isNavigating = false;
  bool _isSearching = false;
  bool _isTrackingStarted = false;
  bool _isBackgroundTrackingEnabled = false;
  bool _isConnected = true;
  bool _isLocationEnabled = true;
  
  List<PlaceResult> _searchResults = [];
  NavigationState? _currentNavigation;
  Timer? _locationTimer;
  Timer? _displayTimer;
  int _updateCounter = 0;
  int _secondsElapsed = 0;
  double _lastSpeed = 0.0;
  int _batteryLevel = 100;
  int _bufferSize = 0;
  bool _isSendingBufferedData = false;
  int _locationWarningCount = 0;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
    _setupNavigationCallbacks();
    _initializeBackgroundService();
    _initializeConnectivity();
    _initializeDataBuffer();
    _initializeLocationMonitoring();
    _updateBatteryLevel(); // Get initial battery level
  }

  void _setupNavigationCallbacks() {
    _navigationService.onMapReady = () {
      setState(() {
        _isMapReady = true;
      });
      print('Map is ready!');
    };

    _navigationService.onMapError = (error) {
      print('Map error: $error');
      _showSnackBar('Map error: $error', Colors.red);
    };

    _navigationService.onRouteCalculated = (routeData) {
      print('Route calculated: $routeData');
      // Route data is handled by the navigation service
    };

    _navigationService.onRouteProgress = (progress) {
      setState(() {
        // Update navigation progress
        _currentNavigation = NavigationState(
          isNavigating: _isNavigating,
          destinationName: _currentNavigation?.destinationName,
          remainingDistanceInMeters: progress['distanceRemaining']?.toDouble(),
          remainingDurationInSeconds: progress['durationRemaining']?.toDouble(),
          currentInstruction: progress['currentInstruction'] != null
              ? NavigationInstruction.fromMap(Map<String, dynamic>.from(progress['currentInstruction']))
              : null,
        );
      });
    };

    _navigationService.onNavigationStarted = () {
      setState(() {
        _isNavigating = true;
      });
    };

    _navigationService.onNavigationStopped = () {
      setState(() {
        _isNavigating = false;
        _currentNavigation = null;
      });
    };

    _navigationService.onArrival = () {
      _showSnackBar('🎉 You have arrived at your destination!', Colors.green);
      setState(() {
        _isNavigating = false;
        _currentNavigation = null;
      });
    };
  }

  Future<void> _requestPermissions() async {
    // Request basic location permissions first
    await [
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
    
    // Request background location permission (Android 10+)
    final backgroundStatus = await Permission.locationAlways.request();
    
    setState(() {
      _isBackgroundTrackingEnabled = backgroundStatus == PermissionStatus.granted;
    });
    
    if (!_isBackgroundTrackingEnabled) {
      _showSnackBar('⚠️ Enable "Allow all the time" for 24/7 tracking', Colors.orange);
    } else {
      _showSnackBar('✅ Background tracking enabled', Colors.green);
    }
  }

  Future<void> _initializeBackgroundService() async {
    // Set vehicle ID for background service
    BackgroundLocationService.setVehicleId(widget.vehicleId);
    
    // Request permission for background task
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLocationWarningDialog() {
    _locationMonitor.showLocationWarningDialog(context);
  }

  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final results = await NavigationService.searchPlaces(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Search error: $e');
      _showSnackBar('Search failed', Colors.red);
    }
  }

Future<void> _selectPlace(PlaceResult place) async {
  try {
    _showSnackBar('Getting directions...', Colors.blue);
    
    // Get place details first
    final placeDetails = await NavigationService.getPlaceDetails(place.placeId);
    
    if (placeDetails != null) {
      // Get current location
      final currentLocation = await NavigationService.getCurrentLocation();
      
      if (currentLocation != null) {
        // Calculate route with traffic using the corrected API
        final route = await NavigationService.calculateRouteWithTraffic(
          startLatitude: currentLocation['latitude']!,
          startLongitude: currentLocation['longitude']!,
          endLatitude: placeDetails.latitude,
          endLongitude: placeDetails.longitude,
        );
        
        if (route != null) {
          _showSnackBar(
            'Route found: ${(route.distanceInMeters / 1000).toStringAsFixed(1)} km, ${(route.durationInSeconds / 60).toStringAsFixed(0)} min', 
            Colors.green
          );
          
          // Start navigation using the calculated route
          final navigationStarted = await NavigationService.startNavigationToCoordinates(
            latitude: placeDetails.latitude,
            longitude: placeDetails.longitude,
            destinationName: place.mainText,
          );
          
          if (!navigationStarted) {
            _showSnackBar('Unable to start navigation. Please try again.', Colors.orange);
          }
        } else {
          _showSnackBar('Unable to calculate route. Please check the destination.', Colors.orange);
        }
      } else {
        _showSnackBar('Unable to get current location. Please enable GPS.', Colors.red);
      }
    } else {
      _showSnackBar('Could not find location details', Colors.red);
    }
    
  } catch (e) {
    print('Navigation error: $e');
    _showSnackBar('Navigation failed. Please try again.', Colors.red);
  } finally {
    _clearSearch();
  }
}



  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  Future<void> _stopNavigation() async {
    try {
      final success = await NavigationService.stopNavigation();
      if (!success) {
        _showSnackBar('Error stopping navigation', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error stopping navigation: $e', Colors.red);
    }
  }

  Future<void> _recenterMap() async {
    try {
      await NavigationService.recenterMap();
      // _showSnackBar('🎯 Map recentered', Colors.blue);
    } catch (e) {
      _showSnackBar('Error recentering map: $e', Colors.red);
    }
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '';
    
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(double? seconds) {
    if (seconds == null) return '';
    
    final minutes = (seconds / 60).round();
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // MAP VIEW - Updated to use ola_navigation_view
          AndroidView(
            viewType: 'ola_navigation_view',
            creationParams: {
              'apiKey': 'u5x5JZtduMMw2SEIvz37Y6YGkf71YJKpFDCpA85y',
            },
            creationParamsCodec: const StandardMessageCodec(),
          ),
          
          // LOCATION WARNING BANNER
          if (!_isLocationEnabled)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_off,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'CRITICAL: Location Services Disabled!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'MFB Field tracking requires location. Enable immediately! (Warning #$_locationWarningCount)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _locationMonitor.openLocationSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE53E3E),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'ENABLE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // USER INFO AND SEARCH BAR
          if (!_isNavigating) 
            Positioned(
              top: (!_isLocationEnabled ? 80 : 0) + MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // User Info Card
                  Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53E3E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.username} • ${widget.vehicleId}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Search Bar
                  Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      hintText: 'Search for places',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isSearching = value.isNotEmpty;
                      });
                      _searchPlaces(value);
                    },
                    onTap: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                ),
              ),
                ],
              ),
            ),

          // START/STOP TRACKING BUTTONS
          if (!_isNavigating && !_isSearching)
            Positioned(
              top: (!_isLocationEnabled ? 80 : 0) + MediaQuery.of(context).padding.top + 120,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isTrackingStarted)
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: _startLocationTracking,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow, color: Colors.white, size: 20),
                              SizedBox(width: 4),
                              Text(
                                'START',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  if (_isTrackingStarted) ...[
                    // Tracking Status Indicator with Counter
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TRACKING',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '$_updateCounter updates',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 8,
                                  ),
                                ),
                                Text(
                                  '${_secondsElapsed}s elapsed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 7,
                                  ),
                                ),
                                Text(
                                  'ID: ${widget.vehicleId}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 7,
                                  ),
                                ),
                                Text(
                                  'Speed: ${_lastSpeed.round()} km/h',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 7,
                                  ),
                                ),
                                Text(
                                  'Battery: $_batteryLevel%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 7,
                                  ),
                                ),
                                Text(
                                  _isConnected ? '🌐 Online' : '🚫 Offline',
                                  style: TextStyle(
                                    color: _isConnected ? Colors.white : Colors.red[300],
                                    fontWeight: FontWeight.w400,
                                    fontSize: 7,
                                  ),
                                ),
                                Text(
                                  _isLocationEnabled ? '📍 Location ON' : '🚨 Location OFF',
                                  style: TextStyle(
                                    color: _isLocationEnabled ? Colors.green[300] : Colors.red[300],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 7,
                                  ),
                                ),
                                if (!_isLocationEnabled && _locationWarningCount > 0)
                                  Text(
                                    'Warnings: $_locationWarningCount',
                                    style: TextStyle(
                                      color: Colors.red[300],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 7,
                                    ),
                                  ),
                                Text(
                                  'Buffer: $_bufferSize',
                                  style: TextStyle(
                                    color: _bufferSize > 0 ? Colors.orange[300] : Colors.white,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 7,
                                  ),
                                ),
                                if (_isSendingBufferedData)
                                  Text(
                                    'Sending...',
                                    style: TextStyle(
                                      color: Colors.green[300],
                                      fontWeight: FontWeight.w400,
                                      fontSize: 7,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Stop Button
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: _stopLocationTracking,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53E3E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stop, color: Colors.white, size: 20),
                              SizedBox(width: 4),
                              Text(
                                'STOP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          // SEARCH RESULTS
          if (_isSearching && _searchResults.isNotEmpty)
            Positioned(
              top: (!_isLocationEnabled ? 80 : 0) + MediaQuery.of(context).padding.top + 110,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.blue),
                        title: Text(
                          place.mainText,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(place.secondaryText),
                        onTap: () => _selectPlace(place),
                      );
                    },
                  ),
                ),
              ),
            ),
          
          // NAVIGATION CONTROLS
          if (_isNavigating) ...[
            // Navigation Header
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _stopNavigation,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Navigating to',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _currentNavigation?.destinationName ?? 'Destination',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_currentNavigation?.remainingDistanceInMeters != null ||
                              _currentNavigation?.remainingDurationInSeconds != null)
                            Text(
                              '${_formatDistance(_currentNavigation?.remainingDistanceInMeters)} • ${_formatDuration(_currentNavigation?.remainingDurationInSeconds)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Navigation Instructions
            if (_currentNavigation?.currentInstruction != null)
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentNavigation!.currentInstruction!.text,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_currentNavigation!.currentInstruction!.roadName?.isNotEmpty == true)
                                    Text(
                                      'on ${_currentNavigation!.currentInstruction!.roadName}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              color: Colors.grey.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDistance(_currentNavigation!.currentInstruction!.distanceToManeuver),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          
          // Loading overlay
          if (!_isMapReady)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading map...'),
                  ],
                ),
              ),
            ),
        ],
      ),
      
      // Add small floating action button for recentering map
      floatingActionButton: _isMapReady ? SizedBox(
        width: 45,
        height: 45,
        child: FloatingActionButton(
          onPressed: _recenterMap,
          backgroundColor: Colors.white,
          elevation: 3,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 20),
          tooltip: 'Recenter Map',
        ),
      ) : null,
    );
  }

  // Location tracking methods
  void _startLocationTracking() async {
    try {
      setState(() {
        _isTrackingStarted = true;
        _updateCounter = 0; // Reset counter when starting
        _secondsElapsed = 0; // Reset elapsed time
        _lastSpeed = 0.0; // Reset speed
      });
      
      // Update battery level
      await _updateBatteryLevel();
      
      // Enable wake lock to prevent screen from turning off during tracking
      await WakelockPlus.enable();
      
      _showSnackBar('🟢 Location tracking started', Colors.green);
      
      // Start background foreground service for continuous tracking
      if (_isBackgroundTrackingEnabled) {
        await FlutterForegroundTask.startService(
          notificationTitle: '🚒 MFB Field Tracking',
          notificationText: '📍 Starting location tracking...',
          callback: () => BackgroundLocationService(),
        );
        _showSnackBar('🌐 Background tracking active', Colors.blue);
      } else {
        _showSnackBar('⚠️ Background tracking disabled - will pause when locked', Colors.orange);
      }
      
      // Send initial location immediately
      await _sendLocationUpdate();
      
      // Start periodic location updates every 5 seconds (foreground backup)
      _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _sendLocationUpdate();
      });
      
      // Start display timer for elapsed time (every second)
      _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsElapsed++;
        });
      });
      
    } catch (e) {
      print('Error starting location tracking: $e');
      _showSnackBar('❌ Failed to start tracking', Colors.red);
      setState(() {
        _isTrackingStarted = false;
      });
    }
  }
  
  void _stopLocationTracking() async {
    // Stop foreground service
    await FlutterForegroundTask.stopService();
    
    // Disable wake lock
    await WakelockPlus.disable();
    
    // Cancel foreground timers
    _locationTimer?.cancel();
    _displayTimer?.cancel();
    _locationTimer = null;
    _displayTimer = null;
    
    setState(() {
      _isTrackingStarted = false;
    });
    
    _showSnackBar('🔴 Location tracking stopped (${_updateCounter} updates sent)', Colors.orange);
  }
  
  Future<void> _updateBatteryLevel() async {
    try {
      final battery = Battery();
      final batteryLevel = await battery.batteryLevel;
      setState(() {
        _batteryLevel = batteryLevel;
      });
    } catch (e) {
      print('Error getting battery level: $e');
    }
  }

  Future<void> _initializeConnectivity() async {
    await _connectivityService.initialize();
    
    // Set initial connectivity state
    _isConnected = await _connectivityService.checkConnectivity();
    
    // Listen to connectivity changes
    _connectivityService.onConnectivityChanged = (bool isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
      
      if (!isConnected) {
        _showSnackBar('🚫 No internet connection - Data will be buffered', Colors.red);
      } else {
        _showSnackBar('✅ Internet connection restored - Sending buffered data', Colors.green);
      }
    };
    
    print('🌐 Connectivity service initialized. Connected: $_isConnected');
  }

  Future<void> _initializeDataBuffer() async {
    await _dataBuffer.initialize();
    
    // Set up buffer monitoring callbacks
    _dataBuffer.onBufferSizeChanged = (int bufferSize) {
      setState(() {
        _bufferSize = bufferSize;
      });
    };
    
    _dataBuffer.onSendingStateChanged = (bool isSending) {
      setState(() {
        _isSendingBufferedData = isSending;
      });
    };
    
    // Get initial buffer status
    final bufferStatus = _dataBuffer.getBufferStatus();
    setState(() {
      _bufferSize = bufferStatus['bufferSize'];
      _isSendingBufferedData = bufferStatus['isSending'];
    });
    
    print('📦 Data buffer service initialized. Buffer size: $_bufferSize');
  }

  Future<void> _initializeLocationMonitoring() async {
    await _locationMonitor.initialize();
    
    // Set up location monitoring callbacks
    _locationMonitor.onLocationStatusChanged = (bool isLocationEnabled) {
      setState(() {
        _isLocationEnabled = isLocationEnabled;
      });
      
      if (!isLocationEnabled) {
        _showLocationWarningDialog();
      }
    };
    
    _locationMonitor.onLocationWarning = (String message) {
      setState(() {
        _locationWarningCount = _locationMonitor.warningCount;
      });
      _showSnackBar(message, Colors.red);
    };
    
    // Get initial location status
    _isLocationEnabled = await _locationMonitor.forceCheckLocation();
    setState(() {
      _isLocationEnabled = _isLocationEnabled;
    });
    
    // Start monitoring
    _locationMonitor.startMonitoring();
    
    print('🔍 Location monitoring service initialized. Location enabled: $_isLocationEnabled');
  }

  /// Restart location monitoring when app resumes
  Future<void> _restartLocationMonitoring() async {
    try {
      print('🔄 [LOCATION_MONITOR] Restarting location monitoring...');
      
      // Stop current monitoring
      _locationMonitor.stopMonitoring();
      
      // Wait a moment for cleanup
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Trigger immediate location check
      await _locationMonitor.triggerImmediateCheck();
      
      // Get current status
      final isLocationEnabled = _locationMonitor.isLocationEnabled;
      setState(() {
        _isLocationEnabled = isLocationEnabled;
      });
      
      // If location is disabled, show warning immediately
      if (!isLocationEnabled) {
        _showLocationWarningDialog();
      }
      
      // Restart monitoring with more frequent checks (1 second interval)
      _locationMonitor.startMonitoring(checkInterval: const Duration(seconds: 1));
      
      print('✅ [LOCATION_MONITOR] Location monitoring restarted. Location enabled: $isLocationEnabled');
    } catch (e) {
      print('❌ [LOCATION_MONITOR] Error restarting location monitoring: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is in background or paused
        _connectivityService.setAppState(isInBackground: true);
        break;
      case AppLifecycleState.resumed:
        // App is in foreground - restart location monitoring
        _connectivityService.setAppState(isInBackground: false);
        _restartLocationMonitoring();
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        _connectivityService.setAppState(isInBackground: true);
        break;
    }
  }


  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // Get real battery level
    await _updateBatteryLevel();
    
    // Generate realistic dynamic values
    final DateTime now = DateTime.now();
    final random = (now.millisecondsSinceEpoch % 100);
    
    // Use real battery level
    final batteryLevel = _batteryLevel;
    
    final phoneMode = batteryLevel < 50 ? "BatterySaver" : 
                     batteryLevel > 80 ? "Normal" : "Optimized";
    
    // Simulate GPS satellite count (4-12 satellites)
    final satellites = 4 + (random % 9);
    
    // Generate additional device parameters based on API response structure
    final isRoot = random < 10 ? 1 : 0; // 10% chance device is rooted
    final isLong = random < 30 ? 1 : 0; // 30% chance for long session
    final direction = random * 3.6; // 0-359 degrees based on random
    final powerSavingMode = batteryLevel < 30 ? 1 : 0;
    final performanceMode = batteryLevel > 70 ? 1 : 0;
    final flightMode = 0; // Always 0 for normal operation
    final backgroundRestrictedMode = random < 20 ? 1 : 0;
    final signalStrength = -50 - (random % 50); // -50 to -99 dBm
    
    return {
      'unitId': widget.vehicleId, // Use the vehicle ID from login
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
  
  Future<void> _sendLocationUpdate() async {
    try {
      // Update battery level
      await _updateBatteryLevel();
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        _showSnackBar('⚠️ Please enable GPS location services', Colors.orange);
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions are denied');
          _showSnackBar('⚠️ Location permission required for tracking', Colors.red);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions are permanently denied');
        _showSnackBar('⚠️ Please enable location permission in settings', Colors.red);
        return;
      }

      // Get fresh GPS coordinates using Geolocator with speed
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Add timeout
      );
      
      // Calculate real speed from GPS (convert m/s to km/h)
      final double realSpeed = position.speed * 3.6; // m/s to km/h conversion
      final int speedKmh = realSpeed.isNaN || realSpeed < 0 ? 0 : realSpeed.round();
      
      // Generate dynamic values for more realistic data
      final deviceInfo = await _getDeviceInfo();
      
      // Get unique device ID
      final deviceId = await DeviceIdService.getDeviceId();
      
      // Get next sequential timestamp (5 seconds apart) from data buffer
      final nextTimestamp = _dataBuffer.getNextSequentialTimestamp();
      final timestampString = nextTimestamp.toIso8601String().substring(0, 19) + 'Z';
        
      // Prepare API payload with all parameters from API response structure
      final Map<String, dynamic> payload = {
        "storedProcedureName": "sp_HandleDeviceLocation",
        "DbType": "SQL",
        "parameters": {
          "mode": 1,
          "UnitId": deviceInfo['unitId'],
          "DeviceId": deviceId, // Unique device identifier
          "Latitude": position.latitude,   // Fresh GPS coordinates
          "Longitude": position.longitude, // Fresh GPS coordinates
          "Speed": speedKmh, // 100% Real GPS speed in km/h
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
        
        print('📤 Preparing SEQUENTIAL GPS update: Lat: ${position.latitude}, Lng: ${position.longitude}, Speed: ${speedKmh} km/h');
        print('📤 Sequential Timestamp: $timestampString');
        
        // Use data buffer service to handle sending (with offline buffering)
        await _dataBuffer.sendLocationData(payload);
        
        // Update counter and UI
        _updateCounter++;
        setState(() {
          _lastSpeed = speedKmh.toDouble();
        });
        
        print('✅ Sequential update #$_updateCounter prepared for timestamp: $timestampString');
        
        // Show success message less frequently to avoid spam
        if (_isTrackingStarted && _updateCounter % 5 == 0) { // Show every 5th update
          _showSnackBar('📍 ${_updateCounter} sequential updates prepared', Colors.blue);
        }
      
    } catch (e) {
      print('❌ Error in location update: $e');
      // Silent error handling
    }
  }

  @override
  void dispose() async {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Stop background services
    await FlutterForegroundTask.stopService();
    await WakelockPlus.disable();
    
    // Cancel timers
    _locationTimer?.cancel();
    _displayTimer?.cancel();
    
    // Dispose controllers
    _searchController.dispose();
    _searchFocus.dispose();
    
    // Dispose services
    _connectivityService.dispose();
    _locationMonitor.dispose();
    
    super.dispose();
  }
}

// ==========================================
// ADDITIONAL DATA MODELS
// ==========================================

class NavigationState {
  final bool isNavigating;
  final String? destinationName;
  final double? remainingDistanceInMeters;
  final double? remainingDurationInSeconds;
  final NavigationInstruction? currentInstruction;

  NavigationState({
    required this.isNavigating,
    this.destinationName,
    this.remainingDistanceInMeters,
    this.remainingDurationInSeconds,
    this.currentInstruction,
  });
}

class NavigationInstruction {
  final String text;
  final String maneuverType;
  final double distanceToManeuver;
  final String? roadName;

  NavigationInstruction({
    required this.text,
    required this.maneuverType,
    required this.distanceToManeuver,
    this.roadName,
  });

  factory NavigationInstruction.fromMap(Map<String, dynamic> map) {
    return NavigationInstruction(
      text: map['text'] ?? '',
      maneuverType: map['maneuverType'] ?? '',
      distanceToManeuver: (map['distanceToManeuver'] ?? 0.0).toDouble(),
      roadName: map['roadName'],
    );
  }
}