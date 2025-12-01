import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart'; // Import NavigationScreen
// Note: Other screen imports kept for future use (reports_screen, profile_screen, emergency_screen, notifications_screen)

class MainScreen extends StatefulWidget {
  final String vehicleId;
  final String username;
  
  const MainScreen({super.key, required this.vehicleId, required this.username});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check if location permission is already granted
    final locationStatus = await Permission.location.status;
    setState(() {
      _permissionsGranted = locationStatus == PermissionStatus.granted;
    });
  }

  Future<void> _requestPermissions() async {
    // Request location permission
    final locationStatus = await Permission.location.request();
    
    // Also request background location if available
    if (locationStatus == PermissionStatus.granted) {
      await Permission.locationAlways.request();
    }
    
    setState(() {
      _permissionsGranted = locationStatus == PermissionStatus.granted;
    });
    
    if (!_permissionsGranted) {
      // Show dialog if permission was denied
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Location permission is required for this app to function properly. '
              'Please enable location access in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show permission request screen if permissions not granted
    if (!_permissionsGranted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 80,
                  color: Color(0xFFE53E3E),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Location Permission Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'This app needs location access to provide emergency services and navigation.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Grant Permission',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Show only the NavigationScreen (homepage) - bottom navigation removed
    return NavigationScreen(vehicleId: widget.vehicleId, username: widget.username);
  }
}
