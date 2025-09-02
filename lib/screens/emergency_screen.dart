import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Emergency Actions',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFE53E3E),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Alert Card
            _buildEmergencyAlertCard(context),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildQuickActionsGrid(context),
            
            const SizedBox(height: 24),
            
            // Emergency Contacts
            const Text(
              'Emergency Contacts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildEmergencyContacts(context),
            
            const SizedBox(height: 24),
            
            // Recent Incidents
            const Text(
              'Recent Incidents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildRecentIncidents(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyAlertCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53E3E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emergency,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'EMERGENCY ALERT',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Press and hold for 3 seconds to trigger emergency response',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onLongPress: () => _triggerEmergencyAlert(context),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Center(
                child: Text(
                  'HOLD',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE53E3E),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      {
        'title': 'Fire Incident',
        'icon': Icons.local_fire_department,
        'color': Colors.red,
        'action': () => _reportIncident(context, 'Fire'),
      },
      {
        'title': 'Medical Emergency',
        'icon': Icons.medical_services,
        'color': Colors.green,
        'action': () => _reportIncident(context, 'Medical'),
      },
      {
        'title': 'Traffic Accident',
        'icon': Icons.car_crash,
        'color': Colors.orange,
        'action': () => _reportIncident(context, 'Accident'),
      },
      {
        'title': 'Gas Leak',
        'icon': Icons.gas_meter,
        'color': Colors.blue,
        'action': () => _reportIncident(context, 'Gas Leak'),
      },
      {
        'title': 'Building Collapse',
        'icon': Icons.domain_disabled,
        'color': Colors.brown,
        'action': () => _reportIncident(context, 'Building'),
      },
      {
        'title': 'Other Emergency',
        'icon': Icons.warning,
        'color': Colors.purple,
        'action': () => _reportIncident(context, 'Other'),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: action['action'] as VoidCallback,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      size: 32,
                      color: action['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyContacts(BuildContext context) {
    final contacts = [
      {'name': 'Fire Emergency', 'number': '101', 'icon': Icons.local_fire_department},
      {'name': 'Police', 'number': '100', 'icon': Icons.local_police},
      {'name': 'Ambulance', 'number': '108', 'icon': Icons.medical_services},
      {'name': 'Disaster Management', 'number': '1070', 'icon': Icons.emergency},
    ];

    return Column(
      children: contacts.map((contact) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE53E3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              contact['icon'] as IconData,
              color: const Color(0xFFE53E3E),
              size: 24,
            ),
          ),
          title: Text(
            contact['name'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          subtitle: Text(
            contact['number'] as String,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: IconButton(
            onPressed: () => _makeCall(context, contact['number'] as String),
            icon: const Icon(Icons.call, color: Color(0xFFE53E3E)),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildRecentIncidents() {
    final incidents = [
      {
        'type': 'Fire',
        'location': 'Andheri West',
        'time': '2 hours ago',
        'status': 'Active',
      },
      {
        'type': 'Medical',
        'location': 'Bandra East',
        'time': '4 hours ago',
        'status': 'Resolved',
      },
      {
        'type': 'Accident',
        'location': 'Highway',
        'time': '6 hours ago',
        'status': 'Resolved',
      },
    ];

    return Column(
      children: incidents.map((incident) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: incident['status'] == 'Active' ? Colors.orange : Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            '${incident['type']} - ${incident['location']}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          subtitle: Text(
            incident['time'] as String,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: incident['status'] == 'Active' 
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              incident['status'] as String,
              style: TextStyle(
                color: incident['status'] == 'Active' ? Colors.orange : Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  void _triggerEmergencyAlert(BuildContext context) {
    HapticFeedback.heavyImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emergency, color: Color(0xFFE53E3E)),
            const SizedBox(width: 8),
            const Text('Emergency Alert Triggered'),
          ],
        ),
        content: const Text(
          'Emergency response has been notified. Help is on the way.\n\nIncident ID: EMG-2024-${1001}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent to control room'),
                  backgroundColor: Color(0xFFE53E3E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _reportIncident(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report $type Incident'),
        content: Text('Quick reporting for $type emergency incidents.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$type incident reported')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
            ),
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _makeCall(BuildContext context, String number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Emergency Call'),
        content: Text('Call $number now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling $number...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
            ),
            child: const Text('Call', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
