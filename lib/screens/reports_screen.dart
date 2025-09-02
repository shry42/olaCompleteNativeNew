import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Case Reports',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFE53E3E),
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Resolved'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsList('Active Cases', _activeCases),
          _buildReportsList('Pending Cases', _pendingCases),
          _buildReportsList('Resolved Cases', _resolvedCases),
          _buildReportsList('All Cases', [..._activeCases, ..._pendingCases, ..._resolvedCases]),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReportDialog(),
        backgroundColor: const Color(0xFFE53E3E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildReportsList(String title, List<CaseReport> cases) {
    if (cases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${title.toLowerCase()} found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final caseReport = cases[index];
        return _buildCaseCard(caseReport);
      },
    );
  }

  Widget _buildCaseCard(CaseReport caseReport) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCaseDetails(caseReport),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(caseReport.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      caseReport.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    caseReport.id,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                caseReport.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                caseReport.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      caseReport.location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(caseReport.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.orange;
      case 'pending':
        return Colors.amber;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showCaseDetails(CaseReport caseReport) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            caseReport.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(caseReport.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            caseReport.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Case ID: ${caseReport.id}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      caseReport.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            'Location',
                            caseReport.location,
                            Icons.location_on,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailItem(
                            'Time',
                            _formatTime(caseReport.timestamp),
                            Icons.access_time,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      'Assigned Officer',
                      caseReport.assignedOfficer,
                      Icons.person,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Case Report'),
        content: const Text('This feature will allow officers to create new case reports.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
            ),
            child: const Text('Add Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Sample data
  final List<CaseReport> _activeCases = [
    CaseReport(
      id: 'FIR-2024-001',
      title: 'Building Fire at Commercial Complex',
      description: 'Fire reported at XYZ Shopping Mall, 3rd floor. Multiple fire tenders dispatched. Evacuation in progress.',
      location: 'Andheri West, Mumbai',
      status: 'Active',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      assignedOfficer: 'Inspector Raj Sharma',
    ),
    CaseReport(
      id: 'FIR-2024-002',
      title: 'Vehicle Fire on Highway',
      description: 'Car caught fire on Western Express Highway near Kandivali. Traffic management required.',
      location: 'Western Express Highway',
      status: 'Active',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      assignedOfficer: 'Sub-Inspector Priya Patel',
    ),
  ];

  final List<CaseReport> _pendingCases = [
    CaseReport(
      id: 'FIR-2024-003',
      title: 'Gas Leak Complaint',
      description: 'Residents reported gas smell in residential building. Investigation required.',
      location: 'Bandra East, Mumbai',
      status: 'Pending',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      assignedOfficer: 'Inspector Amit Singh',
    ),
  ];

  final List<CaseReport> _resolvedCases = [
    CaseReport(
      id: 'FIR-2024-004',
      title: 'Kitchen Fire in Restaurant',
      description: 'Small kitchen fire in local restaurant. Successfully extinguished with minimal damage.',
      location: 'Colaba, Mumbai',
      status: 'Resolved',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      assignedOfficer: 'Inspector Maya Joshi',
    ),
    CaseReport(
      id: 'FIR-2024-005',
      title: 'Electrical Short Circuit',
      description: 'Electrical fire in office building. Power supply cut and fire extinguished.',
      location: 'BKC, Mumbai',
      status: 'Resolved',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      assignedOfficer: 'Sub-Inspector Rahul Kumar',
    ),
  ];
}

class CaseReport {
  final String id;
  final String title;
  final String description;
  final String location;
  final String status;
  final DateTime timestamp;
  final String assignedOfficer;

  CaseReport({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.timestamp,
    required this.assignedOfficer,
  });
}
