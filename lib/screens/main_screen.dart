import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart'; // Import NavigationScreen and PermissionRequestScreen
import 'reports_screen.dart';
import 'profile_screen.dart';
import 'emergency_screen.dart';
import 'notifications_screen.dart';

class MainScreen extends StatefulWidget {
  final String vehicleId;
  final String username;
  
  const MainScreen({super.key, required this.vehicleId, required this.username});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _permissionsGranted = false;
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _screens = [
      NavigationScreen(vehicleId: widget.vehicleId, username: widget.username), // Home - Navigation/Maps
      const ReportsScreen(),    // Reports - Case monitoring
      const EmergencyScreen(),  // Emergency - Quick actions
      const NotificationsScreen(), // Notifications - Alerts
      const ProfileScreen(),    // Profile - Officer details
    ];
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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFE53E3E),
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_outlined),
              activeIcon: Icon(Icons.emergency),
              label: 'Emergency',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
