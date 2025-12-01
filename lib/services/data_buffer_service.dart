import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class DataBufferService {
  static const String _apiUrl = 'http://115.242.59.130:9000/api/Common/CommonAPI';
  static const String _bufferKey = 'location_data_buffer';
  static const String _lastTimestampKey = 'last_successful_timestamp';
  
  // Singleton pattern
  static final DataBufferService _instance = DataBufferService._internal();
  factory DataBufferService() => _instance;
  DataBufferService._internal();

  // Buffer management
  List<Map<String, dynamic>> _dataBuffer = [];
  DateTime _lastSuccessfulTimestamp = DateTime.now();
  DateTime _nextSequentialTimestamp = DateTime.now();
  bool _isSendingBufferedData = false;
  Timer? _rapidSendTimer;
  
  // Connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  // Callbacks
  Function(int bufferSize)? onBufferSizeChanged;
  Function(bool isSending)? onSendingStateChanged;
  Function(int count)? onBufferedDataSent; // Callback for successful buffered data sends

  /// Initialize the data buffer service
  Future<void> initialize() async {
    print('🔄 [BUFFER] Initializing DataBufferService...');
    
    // Load existing buffer from storage
    await _loadBufferFromStorage();
    
    // Load last successful timestamp
    await _loadLastTimestamp();
    
    // Start connectivity monitoring
    await _startConnectivityMonitoring();
    
    print('✅ [BUFFER] DataBufferService initialized. Buffer size: ${_dataBuffer.length}');
  }

  /// Load buffer data from SharedPreferences
  Future<void> _loadBufferFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bufferJson = prefs.getString(_bufferKey);
      
      if (bufferJson != null) {
        final List<dynamic> bufferList = json.decode(bufferJson);
        _dataBuffer = bufferList.cast<Map<String, dynamic>>();
        print('📦 [BUFFER] Loaded ${_dataBuffer.length} items from storage');
      }
    } catch (e) {
      print('❌ [BUFFER] Error loading buffer from storage: $e');
      _dataBuffer = [];
    }
  }

  /// Save buffer data to SharedPreferences
  Future<void> _saveBufferToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bufferJson = json.encode(_dataBuffer);
      await prefs.setString(_bufferKey, bufferJson);
    } catch (e) {
      print('❌ [BUFFER] Error saving buffer to storage: $e');
    }
  }

  /// Load last successful timestamp from storage
  Future<void> _loadLastTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_lastTimestampKey);
      
      if (timestampString != null) {
        _lastSuccessfulTimestamp = DateTime.parse(timestampString);
        // Set sequential timestamp to be 5 seconds after the last successful timestamp
        _nextSequentialTimestamp = _lastSuccessfulTimestamp.add(const Duration(seconds: 5));
        print('⏰ [BUFFER] Loaded last timestamp: $_lastSuccessfulTimestamp');
        print('⏰ [BUFFER] Set sequential timestamp: $_nextSequentialTimestamp');
      } else {
        // If no previous timestamp, set both to current time
        _nextSequentialTimestamp = DateTime.now();
      }
    } catch (e) {
      print('❌ [BUFFER] Error loading last timestamp: $e');
      _lastSuccessfulTimestamp = DateTime.now();
      _nextSequentialTimestamp = DateTime.now();
    }
  }

  /// Save last successful timestamp to storage
  Future<void> _saveLastTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastTimestampKey, _lastSuccessfulTimestamp.toIso8601String());
    } catch (e) {
      print('❌ [BUFFER] Error saving last timestamp: $e');
    }
  }

  /// Start monitoring connectivity changes
  Future<void> _startConnectivityMonitoring() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(results);
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectivityStatus);
  }

  /// Update connectivity status and handle state changes
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    print('🌐 [BUFFER] Connectivity changed: $_isConnected (was: $wasConnected)');
    
    if (wasConnected != _isConnected) {
      if (!_isConnected) {
        _handleOfflineMode();
      } else {
        _handleOnlineMode();
      }
    }
  }

  /// Handle going offline - stop rapid sending
  void _handleOfflineMode() {
    print('📴 [BUFFER] Going offline - stopping rapid send');
    _stopRapidSending();
  }

  /// Handle coming back online - start rapid sending of buffered data
  void _handleOnlineMode() {
    print('📶 [BUFFER] Coming online - starting rapid send of buffered data');
    if (_dataBuffer.isNotEmpty) {
      _startRapidSending();
    }
  }

  /// Get next sequential timestamp (5 seconds apart)
  /// This ensures timestamps are always in ascending order, even when sending fails
  DateTime getNextSequentialTimestamp() {
    final now = DateTime.now();
    
    // If the next sequential timestamp is in the past, update it to current time
    if (_nextSequentialTimestamp.isBefore(now)) {
      _nextSequentialTimestamp = now;
    }
    
    // Get the current sequential timestamp
    final currentTimestamp = _nextSequentialTimestamp;
    
    // Update for next call (add 5 seconds)
    _nextSequentialTimestamp = _nextSequentialTimestamp.add(const Duration(seconds: 5));
    
    print('⏰ [BUFFER] Generated sequential timestamp: $currentTimestamp (next: $_nextSequentialTimestamp)');
    return currentTimestamp;
  }

  /// Add location data to buffer
  Future<void> addLocationData(Map<String, dynamic> locationData) async {
    // Generate sequential timestamp
    final timestamp = getNextSequentialTimestamp();
    final timestampString = timestamp.toIso8601String().substring(0, 19) + 'Z';
    
    // Create buffered data entry
    final bufferedEntry = {
      'timestamp': timestampString,
      'data': locationData,
      'createdAt': DateTime.now().toIso8601String(),
      'retryCount': 0,
    };
    
    // Add to buffer
    _dataBuffer.add(bufferedEntry);
    
    // Ensure buffer maintains sequential order
    await _ensureSequentialOrder();
    
    // Save to storage
    await _saveBufferToStorage();
    
    // Notify listeners
    onBufferSizeChanged?.call(_dataBuffer.length);
    
    print('📦 [BUFFER] Added location data to buffer. Timestamp: $timestampString, Buffer size: ${_dataBuffer.length}');
    
    // If online, try to send immediately
    if (_isConnected && !_isSendingBufferedData) {
      _startRapidSending();
    }
  }

  /// Ensure buffer maintains sequential timestamp order
  Future<void> _ensureSequentialOrder() async {
    if (_dataBuffer.length <= 1) return;
    
    // Sort buffer by timestamp to maintain sequential order
    _dataBuffer.sort((a, b) {
      final timestampA = DateTime.parse(a['timestamp'].replaceAll('Z', ''));
      final timestampB = DateTime.parse(b['timestamp'].replaceAll('Z', ''));
      return timestampA.compareTo(timestampB);
    });
    
    print('🔄 [BUFFER] Buffer sorted to maintain sequential order');
  }

  /// Start rapid sending of buffered data
  void _startRapidSending() {
    if (_isSendingBufferedData || _dataBuffer.isEmpty || !_isConnected) {
      return;
    }
    
    _isSendingBufferedData = true;
    onSendingStateChanged?.call(true);
    
    print('🚀 [BUFFER] Starting rapid send of ${_dataBuffer.length} buffered items...');
    
    // Use a more flexible approach for sequential sending
    _processBufferedItemsSequentially();
  }

  /// Process buffered items in STRICT SEQUENTIAL order
  /// If any item fails, stop completely and wait for next connectivity change
  Future<void> _processBufferedItemsSequentially() async {
    print('🔄 [BUFFER] Starting STRICT SEQUENTIAL processing of ${_dataBuffer.length} items...');
    
    int sentCount = 0;
    
    while (_dataBuffer.isNotEmpty && _isConnected && _isSendingBufferedData) {
      final success = await _processNextBufferedItem();
      
      if (success) {
        sentCount++;
      }
      
      if (!success) {
        // STRICT SEQUENTIAL: If any item fails, stop completely
        print('❌ [BUFFER] STRICT SEQUENTIAL: Item failed to send. STOPPING all sending until connectivity improves.');
        _stopRapidSending();
        // Notify about total sent count before stopping
        if (sentCount > 0) {
          onBufferedDataSent?.call(sentCount);
        }
        return;
      }
      
      // If we're still connected and have items, continue after a short delay
      if (_dataBuffer.isNotEmpty && _isConnected) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    // Stop sending when done or disconnected
    _stopRapidSending();
    
    // Notify about total sent count
    if (sentCount > 0) {
      onBufferedDataSent?.call(sentCount);
    }
  }

  /// Stop rapid sending
  void _stopRapidSending() {
    _rapidSendTimer?.cancel();
    _rapidSendTimer = null;
    _isSendingBufferedData = false;
    onSendingStateChanged?.call(false);
    print('⏹️ [BUFFER] Stopped rapid sending');
  }

  /// Process next item in buffer - STRICT SEQUENTIAL approach
  /// Returns true if successful, false if failed (stops all processing)
  Future<bool> _processNextBufferedItem() async {
    if (_dataBuffer.isEmpty || !_isConnected) {
      _stopRapidSending();
      return false;
    }
    
    final bufferedItem = _dataBuffer.first;
    
    // Log current sequential order
    final timestamps = getBufferTimestamps();
    print('📋 [BUFFER] Current sequential order: ${timestamps.take(5).join(' → ')}${timestamps.length > 5 ? '...' : ''}');
    
    final success = await _sendBufferedItem(bufferedItem);
    
    if (success) {
      // Remove successful item from buffer
      _dataBuffer.removeAt(0);
      await _saveBufferToStorage();
      onBufferSizeChanged?.call(_dataBuffer.length);
      
      print('✅ [BUFFER] Successfully sent buffered item: ${bufferedItem['timestamp']}. Remaining: ${_dataBuffer.length}');
      return true; // Success - continue processing
    } else {
      // STRICT SEQUENTIAL: If any item fails, stop completely
      // Keep the failed item in buffer with its original timestamp and location
      print('❌ [BUFFER] STRICT SEQUENTIAL: Failed to send item ${bufferedItem['timestamp']}');
      print('🔒 [BUFFER] STOPPING all processing - will retry when connectivity improves');
      print('📍 [BUFFER] Preserving original timestamp: ${bufferedItem['timestamp']}');
      print('📍 [BUFFER] Preserving original location: ${bufferedItem['data']}');
      
      return false; // Failure - stop all processing
    }
  }

  /// Send individual buffered item
  Future<bool> _sendBufferedItem(Map<String, dynamic> bufferedItem) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bufferedItem['data']),
      );
      
      if (response.statusCode == 200) {
        // Update last successful timestamp
        final sentTimestamp = DateTime.parse(bufferedItem['timestamp'].replaceAll('Z', ''));
        _lastSuccessfulTimestamp = sentTimestamp;
        
        // Update sequential timestamp to ensure next timestamp is after the last sent one
        if (sentTimestamp.isAfter(_nextSequentialTimestamp)) {
          _nextSequentialTimestamp = sentTimestamp.add(const Duration(seconds: 5));
        }
        
        await _saveLastTimestamp();
        print('✅ [BUFFER] Successfully sent data with timestamp: $sentTimestamp');
        return true;
      } else {
        print('❌ [BUFFER] Failed to send item ${bufferedItem['timestamp']}: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [BUFFER] Error sending item ${bufferedItem['timestamp']}: $e');
      return false;
    }
  }

  /// Send location data (with buffering if offline)
  Future<void> sendLocationData(Map<String, dynamic> locationData) async {
    if (_isConnected && _dataBuffer.isEmpty) {
      // Direct send if online and no buffer
      final success = await _sendLocationDataDirect(locationData);
      if (!success) {
        // If direct send fails, add to buffer
        await addLocationData(locationData);
      }
    } else {
      // Add to buffer (will be sent when online)
      await addLocationData(locationData);
    }
  }

  /// Send location data directly (without buffering) - Public method
  Future<bool> sendLocationDataDirect(Map<String, dynamic> locationData) async {
    return await _sendLocationDataDirect(locationData);
  }

  /// Send location data directly (without buffering) - Private method
  Future<bool> _sendLocationDataDirect(Map<String, dynamic> locationData) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(locationData),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ [BUFFER] Direct send failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [BUFFER] Direct send error: $e');
      return false;
    }
  }

  /// Get current buffer size
  int get bufferSize => _dataBuffer.length;

  /// Get buffer status
  Map<String, dynamic> getBufferStatus() {
    return {
      'bufferSize': _dataBuffer.length,
      'isConnected': _isConnected,
      'isSending': _isSendingBufferedData,
      'lastSuccessfulTimestamp': _lastSuccessfulTimestamp.toIso8601String(),
      'nextSequentialTimestamp': _nextSequentialTimestamp.toIso8601String(),
      'isSequential': _validateSequentialOrder(),
    };
  }

  /// Clear all buffered data
  Future<void> clearAllBufferedData() async {
    print('🗑️ [BUFFER] Clearing all buffered data...');
    
    // Stop any ongoing sending
    _stopRapidSending();
    
    // Clear the buffer
    _dataBuffer.clear();
    
    // Save empty buffer to storage
    await _saveBufferToStorage();
    
    // Notify about buffer size change
    onBufferSizeChanged?.call(0);
    
    print('✅ [BUFFER] All buffered data cleared');
  }

  /// Validate that buffer maintains sequential order
  bool _validateSequentialOrder() {
    if (_dataBuffer.length <= 1) return true;
    
    for (int i = 1; i < _dataBuffer.length; i++) {
      final prevTimestamp = DateTime.parse(_dataBuffer[i-1]['timestamp'].replaceAll('Z', ''));
      final currTimestamp = DateTime.parse(_dataBuffer[i]['timestamp'].replaceAll('Z', ''));
      
      if (currTimestamp.isBefore(prevTimestamp)) {
        print('❌ [BUFFER] Sequential order violation detected at index $i');
        return false;
      }
    }
    
    return true;
  }

  /// Get buffer timestamps for debugging
  List<String> getBufferTimestamps() {
    return _dataBuffer.map((item) => item['timestamp'] as String).toList();
  }

  /// Clear buffer (use with caution)
  Future<void> clearBuffer() async {
    _dataBuffer.clear();
    await _saveBufferToStorage();
    onBufferSizeChanged?.call(0);
    print('🗑️ [BUFFER] Buffer cleared');
  }

  /// Dispose resources
  void dispose() {
    _rapidSendTimer?.cancel();
    _connectivitySubscription?.cancel();
    print('🔴 [BUFFER] DataBufferService disposed');
  }
}
