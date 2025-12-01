import 'dart:async';
import 'package:geolocator/geolocator.dart';

class StationaryDetectionService {
  static final StationaryDetectionService _instance = StationaryDetectionService._internal();
  factory StationaryDetectionService() => _instance;
  StationaryDetectionService._internal();

  Timer? _stationaryTimer;
  Timer? _locationCheckTimer;
  Position? _lastPosition;
  DateTime? _lastMovementTime;
  bool _isStationary = false;
  bool _isMonitoring = false;
  
  // Configuration
  static const Duration _stationaryThreshold = Duration(minutes: 4);
  static const Duration _locationCheckInterval = Duration(seconds: 30);
  static const double _movementThreshold = 10.0; // meters
  
  // Callbacks
  Function()? onVehicleStationary;
  Function()? onVehicleMoving;
  Function(String message)? onWarningMessage;

  /// Start monitoring for stationary vehicle
  void startMonitoring() {
    if (_isMonitoring) {
      print('⚠️ StationaryDetectionService: Already monitoring');
      return;
    }
    
    _isMonitoring = true;
    print('🚗 StationaryDetectionService: Starting stationary monitoring');
    
    // Start periodic location checks
    _locationCheckTimer = Timer.periodic(_locationCheckInterval, (timer) {
      _checkLocation();
    });
    
    // Initial location check
    _checkLocation();
  }

  /// Stop monitoring for stationary vehicle
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    print('🚗 StationaryDetectionService: Stopping stationary monitoring');
    
    _stationaryTimer?.cancel();
    _locationCheckTimer?.cancel();
    _stationaryTimer = null;
    _locationCheckTimer = null;
    _isStationary = false;
    _lastPosition = null;
    _lastMovementTime = null;
  }

  /// Check current location and detect movement
  Future<void> _checkLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ StationaryDetectionService: Location services disabled');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        print('⚠️ StationaryDetectionService: Location permission denied');
        return;
      }

      // Get current position
      final Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Check if this is the first position
      if (_lastPosition == null) {
        _lastPosition = currentPosition;
        _lastMovementTime = DateTime.now();
        print('🚗 StationaryDetectionService: Initial position recorded');
        return;
      }

      // Calculate distance from last position
      final double distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      print('🚗 StationaryDetectionService: Distance from last position: ${distance.toStringAsFixed(2)}m');

      // Check if vehicle has moved significantly
      if (distance > _movementThreshold) {
        // Vehicle has moved
        if (_isStationary) {
          _isStationary = false;
          _stationaryTimer?.cancel();
          _stationaryTimer = null;
          print('🚗 StationaryDetectionService: Vehicle is moving again');
          onVehicleMoving?.call();
        }
        
        _lastPosition = currentPosition;
        _lastMovementTime = DateTime.now();
      } else {
        // Vehicle is stationary
        if (!_isStationary) {
          _isStationary = true;
          _lastMovementTime = DateTime.now();
          print('🚗 StationaryDetectionService: Vehicle is stationary');
        }
        
        // Check if stationary for more than threshold
        if (_lastMovementTime != null) {
          final stationaryDuration = DateTime.now().difference(_lastMovementTime!);
          
          if (stationaryDuration >= _stationaryThreshold) {
            print('⚠️ StationaryDetectionService: Vehicle stationary for ${stationaryDuration.inMinutes} minutes');
            _showStationaryWarning();
          }
        }
      }
    } catch (e) {
      print('❌ StationaryDetectionService: Error checking location: $e');
    }
  }

  /// Show warning for stationary vehicle
  void _showStationaryWarning() {
    if (_stationaryTimer != null) return; // Already showing warning
    
    print('🚨 StationaryDetectionService: Showing stationary warning');
    
    // Show warning message
    onWarningMessage?.call(
      'Vehicle has been stationary for more than 4 minutes. Is the vehicle still in use?'
    );
    
    // Start timer to show warning dialog
    _stationaryTimer = Timer(const Duration(seconds: 5), () {
      onVehicleStationary?.call();
    });
  }

  /// Reset stationary detection (call when vehicle starts moving)
  void resetStationaryDetection() {
    _isStationary = false;
    _stationaryTimer?.cancel();
    _stationaryTimer = null;
    _lastMovementTime = DateTime.now();
    print('🚗 StationaryDetectionService: Stationary detection reset');
  }

  /// Get current stationary status
  bool get isStationary => _isStationary;
  
  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;
  
  /// Get stationary duration
  Duration? get stationaryDuration {
    if (_lastMovementTime == null) return null;
    return DateTime.now().difference(_lastMovementTime!);
  }

  /// Get last known position
  Position? get lastPosition => _lastPosition;

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
