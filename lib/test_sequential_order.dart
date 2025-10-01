// Test file to demonstrate sequential ordering behavior
// This file is for testing purposes only and can be removed after verification

import 'services/data_buffer_service.dart';

class SequentialOrderTest {
  static Future<void> testSequentialOrdering() async {
    print('🧪 Testing Sequential Ordering Behavior...');
    
    final dataBuffer = DataBufferService();
    await dataBuffer.initialize();
    
    // Simulate adding some location data
    for (int i = 0; i < 5; i++) {
      final testData = {
        'test': 'data_$i',
        'latitude': 19.0760 + (i * 0.001),
        'longitude': 72.8777 + (i * 0.001),
      };
      
      await dataBuffer.addLocationData(testData);
      print('📦 Added test data $i');
    }
    
    // Check buffer status
    final status = dataBuffer.getBufferStatus();
    print('📊 Buffer Status: $status');
    
    // Show timestamps
    final timestamps = dataBuffer.getBufferTimestamps();
    print('⏰ Buffer Timestamps: $timestamps');
    
    // Verify sequential order
    final isSequential = status['isSequential'];
    print('✅ Sequential Order Valid: $isSequential');
    
    // Clean up
    await dataBuffer.clearBuffer();
    print('🧹 Test completed and cleaned up');
  }
}
