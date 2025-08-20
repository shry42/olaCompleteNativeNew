import 'package:flutter/services.dart';

class OlaMapsService {
  static const MethodChannel _channel = MethodChannel('ola_maps_channel');
  
  // ==========================================
  // EXISTING MAP METHODS
  // ==========================================
  
  // Initialize the map
  static Future<bool> initializeMap(String apiKey) async {
    try {
      final bool result = await _channel.invokeMethod('initializeMap', {
        'apiKey': apiKey,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to initialize map: '${e.message}'");
      return false;
    }
  }
  
  // Add marker
  static Future<bool> addMarker({
    required String markerId,
    required double latitude,
    required double longitude,
    String? title,
    String? snippet,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('addMarker', {
        'markerId': markerId,
        'latitude': latitude,
        'longitude': longitude,
        'title': title,
        'snippet': snippet,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to add marker: '${e.message}'");
      return false;
    }
  }

  
  // Remove marker
  static Future<bool> removeMarker(String markerId) async {
    try {
      final bool result = await _channel.invokeMethod('removeMarker', {
        'markerId': markerId,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to remove marker: '${e.message}'");
      return false;
    }
  }
  
  // Zoom to location
  static Future<bool> zoomToLocation(double latitude, double longitude, double zoomLevel) async {
    try {
      final bool result = await _channel.invokeMethod('zoomToLocation', {
        'latitude': latitude,
        'longitude': longitude,
        'zoomLevel': zoomLevel,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to zoom to location: '${e.message}'");
      return false;
    }
  }
  
  // Show current location
  static Future<bool> showCurrentLocation() async {
    try {
      final bool result = await _channel.invokeMethod('showCurrentLocation');
      return result;
    } on PlatformException catch (e) {
      print("Failed to show current location: '${e.message}'");
      return false;
    }
  }
  
  // Hide current location
  static Future<bool> hideCurrentLocation() async {
    try {
      final bool result = await _channel.invokeMethod('hideCurrentLocation');
      return result;
    } on PlatformException catch (e) {
      print("Failed to hide current location: '${e.message}'");
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
  
  // Calculate route between two points
  static Future<RouteResult?> calculateRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    RouteProfile profile = RouteProfile.driving,
  }) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('calculateRoute', {
        'startLatitude': startLatitude,
        'startLongitude': startLongitude,
        'endLatitude': endLatitude,
        'endLongitude': endLongitude,
        'profile': profile.name,
      });
      
      return RouteResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      print("Failed to calculate route: '${e.message}'");
      return null;
    }
  }
  
  // Start navigation to coordinates
  static Future<bool> startNavigationToCoordinates({
    required double latitude,
    required double longitude,
    String? destinationName,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('startNavigationToCoordinates', {
        'latitude': latitude,
        'longitude': longitude,
        'destinationName': destinationName ?? 'Destination',
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to start navigation: '${e.message}'");
      return false;
    }
  }
  
  // Start navigation to place
  static Future<bool> startNavigationToPlace({
    required String placeId,
    required String placeName,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('startNavigationToPlace', {
        'placeId': placeId,
        'placeName': placeName,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to start navigation to place: '${e.message}'");
      return false;
    }
  }
  
  // Stop navigation
  static Future<bool> stopNavigation() async {
    try {
      final bool result = await _channel.invokeMethod('stopNavigation');
      return result;
    } on PlatformException catch (e) {
      print("Failed to stop navigation: '${e.message}'");
      return false;
    }
  }
  
  // Get current navigation state
  static Future<NavigationState?> getNavigationState() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getNavigationState');
      
      if (result == null) return null;
      
      return NavigationState.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      print("Failed to get navigation state: '${e.message}'");
      return null;
    }
  }
  
  // Recenter map to current location
  static Future<bool> recenterMap() async {
    try {
      final bool result = await _channel.invokeMethod('recenterMap');
      return result;
    } on PlatformException catch (e) {
      print("Failed to recenter map: '${e.message}'");
      return false;
    }
  }
  
  // Set navigation mode (following, north-up, etc.)
  static Future<bool> setNavigationMode(NavigationMode mode) async {
    try {
      final bool result = await _channel.invokeMethod('setNavigationMode', {
        'mode': mode.name,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to set navigation mode: '${e.message}'");
      return false;
    }
  }
  
  // Toggle day/night mode
  static Future<bool> setMapTheme(MapTheme theme) async {
    try {
      final bool result = await _channel.invokeMethod('setMapTheme', {
        'theme': theme.name,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to set map theme: '${e.message}'");
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

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'mainText': mainText,
      'secondaryText': secondaryText,
      'fullText': fullText,
      'types': types,
    };
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final List<String> types;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.website,
    this.rating,
    required this.types,
  });

  factory PlaceDetails.fromMap(Map<String, dynamic> map) {
    return PlaceDetails(
      placeId: map['placeId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      phoneNumber: map['phoneNumber'],
      website: map['website'],
      rating: map['rating']?.toDouble(),
      types: List<String>.from(map['types'] ?? []),
    );
  }
}

class RouteResult {
  final double distanceInMeters;
  final double durationInSeconds;
  final List<RoutePoint> routePoints;
  final RouteBounds bounds;
  final String routeId;

  RouteResult({
    required this.distanceInMeters,
    required this.durationInSeconds,
    required this.routePoints,
    required this.bounds,
    required this.routeId,
  });

  factory RouteResult.fromMap(Map<String, dynamic> map) {
    return RouteResult(
      distanceInMeters: (map['distanceInMeters'] ?? 0.0).toDouble(),
      durationInSeconds: (map['durationInSeconds'] ?? 0.0).toDouble(),
      routePoints: (map['routePoints'] as List<dynamic>?)
          ?.map((point) => RoutePoint.fromMap(Map<String, dynamic>.from(point)))
          .toList() ?? [],
      bounds: RouteBounds.fromMap(Map<String, dynamic>.from(map['bounds'] ?? {})),
      routeId: map['routeId'] ?? '',
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

class RouteBounds {
  final double northEastLat;
  final double northEastLng;
  final double southWestLat;
  final double southWestLng;

  RouteBounds({
    required this.northEastLat,
    required this.northEastLng,
    required this.southWestLat,
    required this.southWestLng,
  });

  factory RouteBounds.fromMap(Map<String, dynamic> map) {
    return RouteBounds(
      northEastLat: (map['northEastLat'] ?? 0.0).toDouble(),
      northEastLng: (map['northEastLng'] ?? 0.0).toDouble(),
      southWestLat: (map['southWestLat'] ?? 0.0).toDouble(),
      southWestLng: (map['southWestLng'] ?? 0.0).toDouble(),
    );
  }
}

class NavigationState {
  final bool isNavigating;
  final String? destinationName;
  final double? remainingDistanceInMeters;
  final double? remainingDurationInSeconds;
  final NavigationInstruction? currentInstruction;
  final double? currentSpeed;
  final double? currentLatitude;
  final double? currentLongitude;

  NavigationState({
    required this.isNavigating,
    this.destinationName,
    this.remainingDistanceInMeters,
    this.remainingDurationInSeconds,
    this.currentInstruction,
    this.currentSpeed,
    this.currentLatitude,
    this.currentLongitude,
  });

  factory NavigationState.fromMap(Map<String, dynamic> map) {
    return NavigationState(
      isNavigating: map['isNavigating'] ?? false,
      destinationName: map['destinationName'],
      remainingDistanceInMeters: map['remainingDistanceInMeters']?.toDouble(),
      remainingDurationInSeconds: map['remainingDurationInSeconds']?.toDouble(),
      currentInstruction: map['currentInstruction'] != null 
          ? NavigationInstruction.fromMap(Map<String, dynamic>.from(map['currentInstruction']))
          : null,
      currentSpeed: map['currentSpeed']?.toDouble(),
      currentLatitude: map['currentLatitude']?.toDouble(),
      currentLongitude: map['currentLongitude']?.toDouble(),
    );
  }
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

// ==========================================
// ENUMS
// ==========================================

enum RouteProfile {
  driving,
  walking,
  cycling,
}

enum NavigationMode {
  following,
  northUp,
  free,
}

enum MapTheme {
  day,
  night,
  auto,
}
