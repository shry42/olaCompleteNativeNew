import 'package:shared_preferences/shared_preferences.dart';

class UserSessionService {
  static const String _userIdKey = 'user_id';
  static const String _passwordKey = 'user_password';
  static const String _usernameKey = 'username';
  static const String _vehicleIdKey = 'vehicle_id';

  /// Store user session data
  static Future<void> storeUserSession({
    required String userId,
    required String password,
    required String username,
    required String vehicleId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_passwordKey, password);
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_vehicleIdKey, vehicleId);
      
      print('✅ UserSessionService: User session stored successfully');
    } catch (e) {
      print('❌ UserSessionService: Error storing user session: $e');
    }
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      print('❌ UserSessionService: Error getting user ID: $e');
      return null;
    }
  }

  /// Get stored password
  static Future<String?> getPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_passwordKey);
    } catch (e) {
      print('❌ UserSessionService: Error getting password: $e');
      return null;
    }
  }

  /// Get stored username
  static Future<String?> getUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } catch (e) {
      print('❌ UserSessionService: Error getting username: $e');
      return null;
    }
  }

  /// Get stored vehicle ID
  static Future<String?> getVehicleId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_vehicleIdKey);
    } catch (e) {
      print('❌ UserSessionService: Error getting vehicle ID: $e');
      return null;
    }
  }

  /// Clear user session data
  static Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_passwordKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_vehicleIdKey);
      
      print('✅ UserSessionService: User session cleared successfully');
    } catch (e) {
      print('❌ UserSessionService: Error clearing user session: $e');
    }
  }

  /// Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    try {
      final userId = await getUserId();
      final password = await getPassword();
      return userId != null && password != null;
    } catch (e) {
      print('❌ UserSessionService: Error checking login status: $e');
      return false;
    }
  }

  /// Get all stored user data
  static Future<Map<String, String?>> getAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'userId': prefs.getString(_userIdKey),
        'password': prefs.getString(_passwordKey),
        'username': prefs.getString(_usernameKey),
        'vehicleId': prefs.getString(_vehicleIdKey),
      };
    } catch (e) {
      print('❌ UserSessionService: Error getting all user data: $e');
      return {};
    }
  }

  /// Validate current session with API (optional - for enhanced security)
  static Future<bool> validateSessionWithAPI() async {
    try {
      final userData = await getAllUserData();
      final userId = userData['userId'];
      final password = userData['password'];
      
      if (userId == null || password == null) {
        print('⚠️ UserSessionService: No credentials found for validation');
        return false;
      }
      
      // Import AuthService here to avoid circular dependency
      // We'll just return true for now since we already have valid session data
      // In a production app, you might want to make a lightweight API call to validate
      print('✅ UserSessionService: Session validation passed (stored credentials found)');
      return true;
    } catch (e) {
      print('❌ UserSessionService: Error validating session: $e');
      return false;
    }
  }

  /// Check if session is still valid (basic check)
  static Future<bool> isSessionValid() async {
    try {
      final isLoggedIn = await isUserLoggedIn();
      if (!isLoggedIn) {
        return false;
      }
      
      // Additional validation can be added here
      // For now, if we have stored credentials, consider session valid
      return true;
    } catch (e) {
      print('❌ UserSessionService: Error checking session validity: $e');
      return false;
    }
  }
}
