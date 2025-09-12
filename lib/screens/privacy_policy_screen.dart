import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFFE53E3E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53E3E), Color(0xFFB91C1C)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 50,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'MFB Field',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'MFB Field System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Last Updated
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.update, color: Colors.blue),
                  SizedBox(width: 10),
                  Text(
                    'Last Updated: December 2024',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Emergency Notice
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 10),
                      Text(
                        'Emergency Service Notice',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'This app is designed for emergency response and public safety purposes. Location data collection is essential for emergency vehicle tracking and incident response coordination.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Privacy Policy Content
            _buildSection(
              '1. Information We Collect',
              [
                '• Real-time GPS coordinates for vehicle tracking',
                '• Location accuracy data and GPS satellite count',
                '• Movement data (speed, direction, route)',
                '• Background location for continuous tracking',
                '• Device information (battery, connectivity)',
                '• User account and vehicle assignment data',
              ],
            ),
            
            _buildSection(
              '2. How We Use Your Information',
              [
                '• Emergency vehicle tracking and coordination',
                '• Incident response and route optimization',
                '• Public safety and emergency services',
                '• App optimization and performance monitoring',
                '• Personnel identification and coordination',
              ],
            ),
            
            _buildSection(
              '3. Data Sharing',
              [
                '• MFB Field command centers',
                '• Emergency response coordination systems',
                '• Public safety agencies during emergencies',
                '• Map and navigation services (Ola Maps)',
                '• Cloud storage and backup services',
              ],
            ),
            
            _buildSection(
              '4. Data Security',
              [
                '• All data encrypted in transit and at rest',
                '• Strict access controls and authentication',
                '• Secure, monitored servers',
                '• Regular security audits and testing',
                '• Rapid incident response procedures',
              ],
            ),
            
            _buildSection(
              '5. Data Retention',
              [
                '• Location Data: 30 days operational, 7 years legal',
                '• Account Information: Employment duration + 7 years',
                '• Emergency Records: 10 years for documentation',
                '• Analytics Data: 2 years for app improvement',
              ],
            ),
            
            _buildSection(
              '6. Your Rights',
              [
                '• Control location permissions through device settings',
                '• Access and correct your personal data',
                '• Request data portability',
                '• Object to certain data processing',
                '• Request data deletion (subject to legal requirements)',
              ],
            ),
            
            _buildSection(
              '7. Contact Information',
              [
                'Company: SCS Tech',
                'Email: privacy@scstech.com',
                'Phone: [Your Contact Number]',
                'Address: [Your Company Address]',
                '',
                'For emergency-related inquiries, contact MFB Field directly.',
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text(
                    '© 2024 SCS Tech. All rights reserved.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'This Privacy Policy is effective as of December 2024.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE53E3E),
          ),
        ),
        const SizedBox(height: 10),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(
            point,
            style: const TextStyle(fontSize: 14),
          ),
        )),
        const SizedBox(height: 20),
      ],
    );
  }
}