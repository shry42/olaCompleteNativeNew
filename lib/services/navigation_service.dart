import 'package:flutter/services.dart';

class NavigationService {
  static const MethodChannel _channel = MethodChannel('ola_maps_channel');
  
  // Callbacks  
  Function()? onMapReady;
  Function(String error)? onMapError;
  Function(String error)? onLocationError;
  Function(Map<String, dynamic> routeData)? onRouteCalculated;
  Function(Map<String, dynamic> progress)? onRouteProgress;
  Function()? onNavigationStarted;
  Function()? onNavigationStopped;
  Function()? onArrival;
  
  NavigationService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onMapReady':
        onMapReady?.call();
        break;
      case 'onMapError':
        onMapError?.call(call.arguments as String);
        break;
      case 'onLocationError':
        onLocationError?.call(call.arguments as String);
        break;
      case 'onRouteCalculated':
        onRouteCalculated?.call(Map<String, dynamic>.from(call.arguments));
        break;
      case 'onRouteProgress':
        onRouteProgress?.call(Map<String, dynamic>.from(call.arguments));
        break;
      case 'onNavigationStarted':
        onNavigationStarted?.call();
        break;
      case 'onNavigationStopped':
        onNavigationStopped?.call();
        break;
      case 'onArrival':
        onArrival?.call();
        break;
    }
  }
  
  // Updated method to get real route with traffic
  static Future<RouteResult?> calculateRouteWithTraffic({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('calculateRoute', {
        'startLatitude': startLatitude,
        'startLongitude': startLongitude,
        'endLatitude': endLatitude,
        'endLongitude': endLongitude,
      });
      
      return RouteResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      print("Failed to calculate route: '${e.message}'");
      return null;
    }
  }
  
  // Show route preview before starting navigation
  static Future<bool> showRoutePreview() async {
    try {
      final bool result = await _channel.invokeMethod('showRoutePreview');
      return result;
    } on PlatformException catch (e) {
      print("Failed to show route preview: '${e.message}'");
      return false;
    }
  }
  
  // Enhanced method that calculates route AND shows preview
  static Future<bool> calculateAndShowRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    try {
      // First calculate the route
      final route = await calculateRouteWithTraffic(
        startLatitude: startLatitude,
        startLongitude: startLongitude,
        endLatitude: endLatitude,
        endLongitude: endLongitude,
      );
      
      if (route != null) {
        // Then show the route preview
        final previewShown = await showRoutePreview();
        return previewShown;
      }
      
      return false;
    } catch (e) {
      print("Failed to calculate and show route: $e");
      return false;
    }
  }
  
  // Updated navigation method that uses real SDK
  static Future<bool> startNavigationToCoordinates({
    required double latitude,
    required double longitude,
    String? destinationName,
  }) async {
    try {
      // First get current location
      final currentLocation = await getCurrentLocation();
      
      if (currentLocation != null) {
        // Calculate route with traffic first
        final route = await calculateRouteWithTraffic(
          startLatitude: currentLocation['latitude']!,
          startLongitude: currentLocation['longitude']!,
          endLatitude: latitude,
          endLongitude: longitude,
        );
        
        if (route != null) {
          // Start real navigation
          final bool result = await _channel.invokeMethod('startNavigationToCoordinates', {
            'latitude': latitude,
            'longitude': longitude,
            'destinationName': destinationName ?? 'Destination',
          });
          return result;
        }
      }
      
      return false;
    } on PlatformException catch (e) {
      print("Failed to start navigation: '${e.message}'");
      return false;
    }
  }
  
  // Get current location
  static Future<Map<String, double>?> getCurrentLocation() async {
    try {
      final Map<dynamic, dynamic> result = 
          await _channel.invokeMethod('getCurrentLocation');
      return {
        'latitude': result['latitude'],
        'longitude': result['longitude'],
      };
    } on PlatformException catch (e) {
      print("Failed to get current location: '${e.message}'");
      return null;
    }
  }
  
  // Enable voice instructions
  static Future<bool> enableVoiceInstructions(bool enabled) async {
    try {
      final bool result = await _channel.invokeMethod('enableVoiceInstructions', {
        'enabled': enabled,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to toggle voice instructions: '${e.message}'");
      return false;
    }
  }

  // Search for places using Ola Places API
  static Future<List<PlaceResult>> searchPlaces(String query) async {
    try {
      final List<dynamic> results = await _channel.invokeMethod('searchPlaces', {
        'query': query,
      });
      
      return results.map((result) => PlaceResult.fromMap(Map<String, dynamic>.from(result))).toList();
    } on PlatformException catch (e) {
      print("Failed to search places: '${e.message}'");
      return [];
    }
  }
  
  // Get place details by place ID
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getPlaceDetails', {
        'placeId': placeId,
      });
      
      return PlaceDetails.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      print("Failed to get place details: '${e.message}'");
      return null;
    }
  }
  
  static Future<bool> stopNavigation() async {
    try {
      final bool result = await _channel.invokeMethod('stopNavigation');
      return result;
    } on PlatformException catch (e) {
      print("Failed to stop navigation: '${e.message}'");
      return false;
    }
  }
  
static Future<bool> recenterMap() async {
    try {
      final bool result = await _channel.invokeMethod('recenterMap');
      return result;
    } on PlatformException catch (e) {
      print("Failed to recenter map: '${e.message}'");
      return false;
    }
  }
  
  // NEW: Clear all routes method
  static Future<bool> clearAllRoutes() async {
    try {
      final bool result = await _channel.invokeMethod('clearAllRoutes');
      return result;
    } on PlatformException catch (e) {
      print("Failed to clear all routes: '${e.message}'");
      return false;
    }
  }
}


// ==========================================
// DATA MODELS
// ==========================================

class PlaceResult {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String fullText;
  final List<String> types;

  PlaceResult({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
    required this.types,
  });

  factory PlaceResult.fromMap(Map<String, dynamic> map) {
    return PlaceResult(
      placeId: map['placeId'] ?? '',
      mainText: map['mainText'] ?? '',
      secondaryText: map['secondaryText'] ?? '',
      fullText: map['fullText'] ?? '',
      types: List<String>.from(map['types'] ?? []),
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceDetails.fromMap(Map<String, dynamic> map) {
    return PlaceDetails(
      placeId: map['placeId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }
}

class RouteResult {
  final double distanceInMeters;
  final double durationInSeconds;
  final String routeId;
  final List<RoutePoint> routePoints;

  RouteResult({
    required this.distanceInMeters,
    required this.durationInSeconds,
    required this.routeId,
    required this.routePoints,
  });

  factory RouteResult.fromMap(Map<String, dynamic> map) {
    return RouteResult(
      distanceInMeters: (map['distanceInMeters'] ?? 0.0).toDouble(),
      durationInSeconds: (map['durationInSeconds'] ?? 0.0).toDouble(),
      routeId: map['routeId'] ?? '',
      routePoints: (map['routePoints'] as List<dynamic>?)
          ?.map((point) => RoutePoint.fromMap(Map<String, dynamic>.from(point)))
          .toList() ?? [],
    );
  }
}

class RoutePoint {
  final double latitude;
  final double longitude;

  RoutePoint({required this.latitude, required this.longitude});

  factory RoutePoint.fromMap(Map<String, dynamic> map) {
    return RoutePoint(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }
}

