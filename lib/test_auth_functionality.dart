import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/user_session_service.dart';

/// Test class to verify login/logout functionality
/// This can be used for testing the API integration
class AuthFunctionalityTest {
  
  /// Test login functionality with different scenarios
  static Future<void> testLoginScenarios() async {
    print('🧪 Starting Auth Functionality Tests...\n');
    
    // Test 1: Valid login
    print('Test 1: Valid Login (Vehicle ID: ALP2, Password: 101)');
    final validResult = await AuthService.authenticateUser(
      userId: 'ALP2', // Vehicle ID is used as User ID
      password: '101',
    );
    
    if (validResult != null && validResult['error'] == null) {
      print('✅ Valid login successful');
      print('   User ID: ${validResult['usr_id']}');
      print('   Username: ${validResult['username']}');
      print('   Vehicle ID: ${validResult['vehicleId']}');
    } else if (validResult != null && validResult['error'] == 'already_in_use') {
      print('⚠️ User already in use (expected if already logged in)');
      print('   Message: ${validResult['message']}');
    } else {
      print('❌ Valid login failed');
      print('   Error: ${validResult?['error']}');
      print('   Message: ${validResult?['message']}');
    }
    
    print('\n' + '='*50 + '\n');
    
    // Test 2: Invalid login
    print('Test 2: Invalid Login (Vehicle ID: invalid, Password: invalid)');
    final invalidResult = await AuthService.authenticateUser(
      userId: 'invalid',
      password: 'invalid',
    );
    
    if (invalidResult != null && invalidResult['error'] == 'auth_failed') {
      print('✅ Invalid login correctly rejected');
      print('   Message: ${invalidResult['message']}');
    } else {
      print('❌ Invalid login test failed');
      print('   Result: $invalidResult');
    }
    
    print('\n' + '='*50 + '\n');
    
    // Test 3: Logout functionality
    print('Test 3: Logout (Vehicle ID: ALP2, Password: 101)');
    final logoutResult = await AuthService.logoutUser(
      userId: 'ALP2', // Vehicle ID is used as User ID
      password: '101',
    );
    
    if (logoutResult['success'] == true) {
      print('✅ Logout successful');
      print('   Message: ${logoutResult['message']}');
    } else {
      print('❌ Logout failed');
      print('   Message: ${logoutResult['message']}');
    }
    
    print('\n' + '='*50 + '\n');
    
    // Test 4: Session management
    print('Test 4: Session Management');
    
    // Store session
    await UserSessionService.storeUserSession(
      userId: 'ALP2',
      password: '101',
      username: 'Test User',
      vehicleId: 'ALP2',
    );
    
    // Check if logged in
    final isLoggedIn = await UserSessionService.isUserLoggedIn();
    print('   Is logged in: $isLoggedIn');
    
    // Get user data
    final userData = await UserSessionService.getAllUserData();
    print('   Stored user data: $userData');
    
    // Clear session
    await UserSessionService.clearUserSession();
    
    // Check if logged in after clear
    final isLoggedInAfterClear = await UserSessionService.isUserLoggedIn();
    print('   Is logged in after clear: $isLoggedInAfterClear');
    
    print('\n✅ All tests completed!');
  }
  
  /// Test the "already in use" scenario
  static Future<void> testAlreadyInUseScenario() async {
    print('🧪 Testing "Already In Use" Scenario...\n');
    
    // First login
    print('Step 1: First login attempt');
    final firstLogin = await AuthService.authenticateUser(
      userId: 'ALP2',
      password: '101',
    );
    
    if (firstLogin != null && firstLogin['error'] == null) {
      print('✅ First login successful');
    } else if (firstLogin != null && firstLogin['error'] == 'already_in_use') {
      print('⚠️ User already in use on first login');
    } else {
      print('❌ First login failed: ${firstLogin?['error']}');
    }
    
    // Second login (should show already in use)
    print('\nStep 2: Second login attempt (should show already in use)');
    final secondLogin = await AuthService.authenticateUser(
      userId: 'ALP2',
      password: '101',
    );
    
    if (secondLogin != null && secondLogin['error'] == 'already_in_use') {
      print('✅ Second login correctly shows "already in use"');
      print('   Message: ${secondLogin['message']}');
    } else if (secondLogin != null && secondLogin['error'] == null) {
      print('⚠️ Second login succeeded (user was logged out)');
    } else {
      print('❌ Second login failed: ${secondLogin?['error']}');
    }
    
    print('\n✅ "Already In Use" test completed!');
  }

  /// Test persistent login functionality
  static Future<void> testPersistentLogin() async {
    print('🧪 Testing Persistent Login Functionality...\n');
    
    // Step 1: Clear any existing session
    print('Step 1: Clearing any existing session');
    await UserSessionService.clearUserSession();
    
    // Check if logged in (should be false)
    final isLoggedInBefore = await UserSessionService.isUserLoggedIn();
    print('   Is logged in before: $isLoggedInBefore');
    
    // Step 2: Simulate login and store session
    print('\nStep 2: Simulating login and storing session');
    await UserSessionService.storeUserSession(
      userId: 'ALP2',
      password: '101',
      username: 'Test User',
      vehicleId: 'ALP2',
    );
    
    // Check if logged in (should be true)
    final isLoggedInAfter = await UserSessionService.isUserLoggedIn();
    print('   Is logged in after storing session: $isLoggedInAfter');
    
    // Step 3: Get stored user data
    print('\nStep 3: Retrieving stored user data');
    final userData = await UserSessionService.getAllUserData();
    print('   Stored user data: $userData');
    
    // Step 4: Validate session
    print('\nStep 4: Validating session');
    final isSessionValid = await UserSessionService.isSessionValid();
    print('   Is session valid: $isSessionValid');
    
    // Step 5: Simulate app restart (clear and check again)
    print('\nStep 5: Simulating app restart');
    await UserSessionService.clearUserSession();
    
    final isLoggedInAfterRestart = await UserSessionService.isUserLoggedIn();
    print('   Is logged in after restart (without re-login): $isLoggedInAfterRestart');
    
    // Step 6: Restore session and test again
    print('\nStep 6: Restoring session for persistent login test');
    await UserSessionService.storeUserSession(
      userId: 'ALP2',
      password: '101',
      username: 'Test User',
      vehicleId: 'ALP2',
    );
    
    final isLoggedInAfterRestore = await UserSessionService.isUserLoggedIn();
    print('   Is logged in after restore: $isLoggedInAfterRestore');
    
    print('\n✅ Persistent Login test completed!');
  }
}

/// Widget to run tests from UI
class AuthTestWidget extends StatelessWidget {
  const AuthTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Functionality Test'),
        backgroundColor: const Color(0xFFE53E3E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Authentication Functionality Tests',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will test the login/logout functionality with the API.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await AuthFunctionalityTest.testLoginScenarios();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Run Login/Logout Tests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await AuthFunctionalityTest.testAlreadyInUseScenario();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Test "Already In Use" Scenario',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await AuthFunctionalityTest.testPersistentLogin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Test Persistent Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Check the console output for test results.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
