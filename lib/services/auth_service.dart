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

      // Make the API request
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

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
          // Extract user information from the response
          final userInfo = _extractUserInfo(responseData);
          print('✅ AuthService: User info extracted: $userInfo');
          return userInfo;
        } else {
          // Authentication failed
          print('❌ AuthService: Authentication failed: ${responseData['message']}');
          return null;
        }
      } else {
        // HTTP error
        print('❌ AuthService: HTTP error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      // Network or parsing error
      print('❌ AuthService: Authentication error: $e');
      return null;
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
