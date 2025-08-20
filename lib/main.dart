import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/navigation_service.dart'; // Import your new service

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ola Maps Navigation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const NavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final NavigationService _navigationService = NavigationService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  bool _isMapReady = false;
  bool _isNavigating = false;
  bool _isSearching = false;
  
  List<PlaceResult> _searchResults = [];
  NavigationState? _currentNavigation;
  RouteResult? _currentRoute;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _setupNavigationCallbacks();
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
      setState(() {
        _currentRoute = RouteResult.fromMap(routeData);
      });
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
        _currentRoute = null;
      });
    };

    _navigationService.onArrival = () {
      _showSnackBar('🎉 You have arrived at your destination!', Colors.green);
      setState(() {
        _isNavigating = false;
        _currentNavigation = null;
        _currentRoute = null;
      });
    };
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
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

// ALSO ADD this method to help debug API responses:
Future<void> _testDirectionsAPI() async {
  try {
    final currentLocation = await NavigationService.getCurrentLocation();
    
    if (currentLocation != null) {
      print('🧪 Testing Directions API...');
      print('Current Location: ${currentLocation['latitude']}, ${currentLocation['longitude']}');
      
      // Test with a known destination (Mumbai to Bangalore)
      final route = await NavigationService.calculateRouteWithTraffic(
        startLatitude: currentLocation['latitude']!,
        startLongitude: currentLocation['longitude']!,
        endLatitude: 12.9716, // Bangalore
        endLongitude: 77.5946,
      );
      
      if (route != null) {
        print('✅ API Test Success!');
        print('Distance: ${route.distanceInMeters / 1000} km');
        print('Duration: ${route.durationInSeconds / 60} minutes');
        print('Route Points: ${route.routePoints.length}');
        _showSnackBar('API Test Success! Check console for details.', Colors.green);
      } else {
        print('❌ API Test Failed - No route returned');
        _showSnackBar('API Test Failed - Check console for details', Colors.red);
      }
    }
  } catch (e) {
    print('❌ API Test Error: $e');
    _showSnackBar('API Test Error: $e', Colors.red);
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
          
          // SEARCH BAR (Google Maps style)
          if (!_isNavigating) 
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Material(
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
            ),
          
          // SEARCH RESULTS
          if (_isSearching && _searchResults.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
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
                    IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.white),
                      onPressed: _recenterMap,
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
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