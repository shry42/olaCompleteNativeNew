import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://115.242.59.130:9000/api/Common/CommonAPI';
  
  /// Authenticates user with the provided credentials
  /// Returns a map containing user information if successful, null if failed
  static Future<Map<String, dynamic>?> authenticateUser({
    required String userId,
    required String password,
  }) async {
    try {
      // Debug: Log the credentials being sent (without showing password)
      print('🔐 AuthService: Attempting login with UserId: "$userId"');
      print('🔐 AuthService: Password length: ${password.length}');
      
      // Prepare the request payload
      final Map<String, dynamic> requestBody = {
        "storedProcedureName": "UserValidation",
        "DbType": "SQL",
        "parameters": {
          "mode": 1,
          "UserId": userId,
          "Password": password,
        }
      };

      // Debug: Log the request body
      print('📤 AuthService: Request body: ${json.encode(requestBody)}');
      print('🌐 AuthService: Making request to: $baseUrl');
      print('🌐 AuthService: Request start time: ${DateTime.now()}');

      // Make the API request with reduced timeout
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ AuthService: Request timeout after 15 seconds');
          throw TimeoutException('Request timeout after 15 seconds');
        },
      );
      
      print('🌐 AuthService: Request completed at: ${DateTime.now()}');

      // Debug: Log response details
      print('📥 AuthService: Response status: ${response.statusCode}');
      print('📥 AuthService: Response body: ${response.body}');

      // Check if request was successful
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Debug: Log the parsed response
        print('📊 AuthService: Parsed response: $responseData');
        print('📊 AuthService: Result: ${responseData['result']}');
        print('📊 AuthService: Message: ${responseData['message']}');
        
        // Check if authentication was successful
        if (responseData['result'] == true && responseData['message'] == 'Success') {
          // Check for "already in use" message in the response
          final userInfo = _extractUserInfo(responseData);
          final isAlreadyInUse = _checkIfAlreadyInUse(responseData);
          
          if (isAlreadyInUse) {
            print('⚠️ AuthService: User already active in other devices');
            return {
              'error': 'already_in_use',
              'message': 'User already active in other devices. Please logout from other devices first.',
            };
          }
          
          print('✅ AuthService: User info extracted: $userInfo');
          return userInfo;
        } else {
          // Authentication failed
          print('❌ AuthService: Authentication failed: ${responseData['message']}');
          return {
            'error': 'auth_failed',
            'message': responseData['message'] ?? 'Authentication failed',
          };
        }
      } else {
        // HTTP error
        print('❌ AuthService: HTTP error: ${response.statusCode} - ${response.body}');
        return {
          'error': 'http_error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Network or parsing error
      print('❌ AuthService: Authentication error: $e');
      return {
        'error': 'network_error',
        'message': 'Network error: $e',
      };
    }
  }

  /// Logs out user with the provided credentials
  /// Returns true if successful, false if failed
  static Future<Map<String, dynamic>> logoutUser({
    required String userId,
    required String password,
  }) async {
    try {
      print('🚪 AuthService: Attempting logout with UserId: "$userId"');
      
      // Prepare the request payload for logout (mode: 2)
      final Map<String, dynamic> requestBody = {
        "storedProcedureName": "UserValidation",
        "DbType": "SQL",
        "parameters": {
          "mode": 2, // Mode 2 for logout
          "UserId": userId,
          "Password": password,
        }
      };

      print('📤 AuthService: Logout request body: ${json.encode(requestBody)}');

      // Make the API request with reduced timeout
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));

      print('📥 AuthService: Logout response status: ${response.statusCode}');
      print('📥 AuthService: Logout response body: ${response.body}');

      // Check if request was successful
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Check if logout was successful
        if (responseData['result'] == true && responseData['message'] == 'Success') {
          // Check for successful logout message
          final isLogoutSuccessful = _checkIfLogoutSuccessful(responseData);
          
          if (isLogoutSuccessful) {
            print('✅ AuthService: Logout successful');
            return {
              'success': true,
              'message': 'User successfully logged out',
            };
          } else {
            print('❌ AuthService: Logout failed - unexpected response');
            return {
              'success': false,
              'message': 'Logout failed - unexpected response',
            };
          }
        } else {
          print('❌ AuthService: Logout failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Logout failed',
          };
        }
      } else {
        print('❌ AuthService: Logout HTTP error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ AuthService: Logout error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Checks if the response indicates user is already in use
  static bool _checkIfAlreadyInUse(Map<String, dynamic> responseData) {
    try {
      final commonReportMasterList = responseData['commonReportMasterList'] as List?;
      
      if (commonReportMasterList != null && commonReportMasterList.length >= 2) {
        final userDataString = commonReportMasterList[1]['returnValue'] as String?;
        
        if (userDataString != null && userDataString.isNotEmpty) {
          // Check if the response contains "already active" message
          return userDataString.contains('already active') || 
                 userDataString.contains('already in use') ||
                 userDataString.contains('User already active');
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking if already in use: $e');
      return false;
    }
  }

  /// Checks if the logout response indicates successful logout
  static bool _checkIfLogoutSuccessful(Map<String, dynamic> responseData) {
    try {
      final commonReportMasterList = responseData['commonReportMasterList'] as List?;
      
      if (commonReportMasterList != null && commonReportMasterList.length >= 2) {
        final userDataString = commonReportMasterList[1]['returnValue'] as String?;
        
        if (userDataString != null && userDataString.isNotEmpty) {
          // Check if the response contains successful logout message
          return userDataString.contains('successfully logout') || 
                 userDataString.contains('User successfully logout') ||
                 userDataString.contains('logout');
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking if logout successful: $e');
      return false;
    }
  }

  /// Extracts user information from the API response
  static Map<String, dynamic>? _extractUserInfo(Map<String, dynamic> responseData) {
    try {
      final commonReportMasterList = responseData['commonReportMasterList'] as List?;
      
      if (commonReportMasterList != null && commonReportMasterList.length >= 2) {
        // The second item contains the user data
        final userDataString = commonReportMasterList[1]['returnValue'] as String?;
        
        if (userDataString != null && userDataString.isNotEmpty) {
          // Parse the JSON string from the returnValue
          // Remove the escaped characters and parse
          final cleanJsonString = userDataString
              .replaceAll('\\r\\n', '')
              .replaceAll('\\n', '')
              .replaceAll('\\', '')
              .trim();
          
          // Extract the JSON part between the brackets
          final jsonStart = cleanJsonString.indexOf('[');
          final jsonEnd = cleanJsonString.lastIndexOf(']');
          
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonString = cleanJsonString.substring(jsonStart + 1, jsonEnd);
            
            // Parse the user data
            final userData = json.decode('[$jsonString]') as List;
            
            if (userData.isNotEmpty) {
              final user = userData[0] as Map<String, dynamic>;
              
              return {
                'empid': user['empid'],
                'usr_id': user['usr_id'],
                'fname': user['fname'],
                'lname': user['lname'],
                'username': user['lname'], // Use lname as username (MR USER)
                'vehicleId': user['usr_id'], // Use usr_id as vehicleId (ALP6)
              };
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error extracting user info: $e');
      return null;
    }
  }

  /// Validates if the API is reachable
  static Future<bool> isApiReachable() async {
    try {
      print('🌐 AuthService: Testing API connectivity...');
      final response = await http.get(
        Uri.parse('http://115.242.59.130:9000'),
      ).timeout(const Duration(seconds: 10));
      
      print('🌐 AuthService: API connectivity test - Status: ${response.statusCode}');
      print('🌐 AuthService: API connectivity test - Response: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ AuthService: API connectivity test failed: $e');
      return false;
    }
  }

  /// Tests API connectivity and returns detailed status information
  static Future<Map<String, dynamic>> testApiConnectivityWithStatus() async {
    try {
      print('🌐 AuthService: Testing API connectivity...');
      final response = await http.get(
        Uri.parse('http://115.242.59.130:9000'),
      ).timeout(const Duration(seconds: 10));
      
      print('🌐 AuthService: API connectivity test - Status: ${response.statusCode}');
      print('🌐 AuthService: API connectivity test - Response: ${response.body}');
      
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'error': null,
      };
    } catch (e) {
      print('❌ AuthService: API connectivity test failed: $e');
      return {
        'success': false,
        'statusCode': null,
        'error': e.toString(),
      };
    }
  }

  /// Test the authentication endpoint with debug info
  static Future<void> testAuthenticationEndpoint() async {
    try {
      print('🧪 AuthService: Testing authentication endpoint...');
      
      final testRequestBody = {
        "storedProcedureName": "UserValidation",
        "DbType": "SQL",
        "parameters": {
          "mode": 1,
          "UserId": "test",
          "Password": "test",
        }
      };
      
      print('🧪 AuthService: Test request body: ${json.encode(testRequestBody)}');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(testRequestBody),
      ).timeout(const Duration(seconds: 10));
      
      print('🧪 AuthService: Test response status: ${response.statusCode}');
      print('🧪 AuthService: Test response body: ${response.body}');
      
    } catch (e) {
      print('❌ AuthService: Test authentication endpoint failed: $e');
    }
  }

  /// Test authentication with specific credentials and return detailed result
  static Future<Map<String, dynamic>> testAuthenticationWithCredentials(String userId, String password) async {
    try {
      print('🧪 AuthService: Testing authentication with credentials: $userId');
      
      final requestBody = {
        "storedProcedureName": "UserValidation",
        "DbType": "SQL",
        "parameters": {
          "mode": 1,
          "UserId": userId,
          "Password": password,
        }
      };
      
      print('🧪 AuthService: Test request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));
      
      print('🧪 AuthService: Test response status: ${response.statusCode}');
      print('🧪 AuthService: Test response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          final isSuccess = responseData['result'] == true && responseData['message'] == 'Success';
          
          return {
            'success': isSuccess,
            'statusCode': response.statusCode,
            'message': responseData['message'] ?? 'Unknown response',
            'result': responseData['result'],
            'responseData': responseData,
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': 'Failed to parse response: $e',
            'result': false,
            'responseData': null,
          };
        }
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'HTTP Error: ${response.statusCode}',
          'result': false,
          'responseData': null,
        };
      }
      
    } catch (e) {
      print('❌ AuthService: Test authentication with credentials failed: $e');
      return {
        'success': false,
        'statusCode': null,
        'message': 'Network Error: $e',
        'result': false,
        'responseData': null,
      };
    }
  }
}
