import 'package:flutter/material.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:cursortest/models/flood_alert.dart';
import 'package:cursortest/screens/alert_detail_screen.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Filter states
  String _selectedSeverity = 'All';
  String _selectedTimeFilter = 'All';
  
  // Sample data - in a real app, this would come from a service
  final List<FloodAlert> _alerts = [
    FloodAlert(
      id: '1',
      latitude: 37.7749,
      longitude: -122.4194,
      description: 'Water level rising rapidly in downtown area. Multiple streets are flooded and impassable. Emergency services are on scene.',
      imageUrl: 'https://example.com/flood1.jpg',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      reportedBy: 'Emergency Services',
      severity: 'High',
    ),
    FloodAlert(
      id: '2',
      latitude: 37.7833,
      longitude: -122.4167,
      description: 'Minor flooding in low-lying areas of Riverside Park. Avoid walking through standing water.',
      imageUrl: 'https://example.com/flood2.jpg',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      reportedBy: 'City Parks Department',
      severity: 'Medium',
    ),
    FloodAlert(
      id: '3',
      latitude: 37.7935,
      longitude: -122.4399,
      description: 'Road closed due to severe flooding. Multiple vehicles stranded. Emergency evacuation in progress.',
      imageUrl: 'https://example.com/flood3.jpg',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      reportedBy: 'Police Department',
      severity: 'Critical',
    ),
    FloodAlert(
      id: '4',
      latitude: 37.7694,
      longitude: -122.4862,
      description: 'Minor water accumulation in the area. No immediate danger, but monitor the situation.',
      imageUrl: 'https://example.com/flood4.jpg',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      reportedBy: 'Community Member',
      severity: 'Low',
    ),
  ];
  
  List<FloodAlert> get _filteredAlerts {
    return _alerts.where((alert) {
      // Filter by severity
      if (_selectedSeverity != 'All' && alert.severity != _selectedSeverity) {
        return false;
      }
      
      // Filter by time
      final now = DateTime.now();
      switch (_selectedTimeFilter) {
        case 'Today':
          return alert.timestamp.day == now.day && 
                 alert.timestamp.month == now.month && 
                 alert.timestamp.year == now.year;
        case 'Last 24 Hours':
          return now.difference(alert.timestamp).inHours <= 24;
        case 'Last Week':
          return now.difference(alert.timestamp).inDays <= 7;
        case 'Last Month':
          return now.difference(alert.timestamp).inDays <= 30;
        default:
          return true;
      }
    }).toList();
  }
  
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
  
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Alerts',
                    style: AppTheme.headingMedium.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Severity',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        selected: _selectedSeverity == 'All',
                        onSelected: (selected) {
                          setState(() {
                            _selectedSeverity = 'All';
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Low',
                        selected: _selectedSeverity == 'Low',
                        onSelected: (selected) {
                          setState(() {
                            _selectedSeverity = 'Low';
                          });
                        },
                        color: AppTheme.successGreen,
                      ),
                      _buildFilterChip(
                        label: 'Medium',
                        selected: _selectedSeverity == 'Medium',
                        onSelected: (selected) {
                          setState(() {
                            _selectedSeverity = 'Medium';
                          });
                        },
                        color: Theme.of(context).extension<CustomColors>()?.warning ?? AppTheme.warningOrange,
                      ),
                      _buildFilterChip(
                        label: 'High',
                        selected: _selectedSeverity == 'High',
                        onSelected: (selected) {
                          setState(() {
                            _selectedSeverity = 'High';
                          });
                        },
                        color: AppTheme.errorRed,
                      ),
                      _buildFilterChip(
                        label: 'Critical',
                        selected: _selectedSeverity == 'Critical',
                        onSelected: (selected) {
                          setState(() {
                            _selectedSeverity = 'Critical';
                          });
                        },
                        color: AppTheme.errorRed,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    'Time Period',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        selected: _selectedTimeFilter == 'All',
                        onSelected: (selected) {
                          setState(() {
                            _selectedTimeFilter = 'All';
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Today',
                        selected: _selectedTimeFilter == 'Today',
                        onSelected: (selected) {
                          setState(() {
                            _selectedTimeFilter = 'Today';
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Last 24 Hours',
                        selected: _selectedTimeFilter == 'Last 24 Hours',
                        onSelected: (selected) {
                          setState(() {
                            _selectedTimeFilter = 'Last 24 Hours';
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Last Week',
                        selected: _selectedTimeFilter == 'Last Week',
                        onSelected: (selected) {
                          setState(() {
                            _selectedTimeFilter = 'Last Week';
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Last Month',
                        selected: _selectedTimeFilter == 'Last Month',
                        onSelected: (selected) {
                          setState(() {
                            _selectedTimeFilter = 'Last Month';
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                            side: const BorderSide(color: AppTheme.primaryBlue),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            this.setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: color != null ? Color.fromRGBO(color.red, color.green, color.blue, 0.1) : AppTheme.lightGray,
      selectedColor: color != null ? Color.fromRGBO(color.red, color.green, color.blue, 0.3) : Color.fromRGBO(AppTheme.primaryBlue.red, AppTheme.primaryBlue.green, AppTheme.primaryBlue.blue, 0.3),
      checkmarkColor: color ?? AppTheme.primaryBlue,
      labelStyle: TextStyle(
        color: selected ? (color ?? AppTheme.primaryBlue) : AppTheme.darkBlue,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredAlerts = _filteredAlerts;
    
    return Scaffold(
      backgroundColor: AppTheme.accentWhite,
      appBar: AppBar(
        title: Text(
          'Flood Alerts',
          style: AppTheme.headingMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter summary
          if (_selectedSeverity != 'All' || _selectedTimeFilter != 'All')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Color.fromRGBO(AppTheme.lightBlue.red, AppTheme.lightBlue.green, AppTheme.lightBlue.blue, 0.3),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing ${_selectedSeverity != 'All' ? _selectedSeverity : ''} alerts ${_selectedTimeFilter != 'All' ? 'from $_selectedTimeFilter' : ''}',
                      style: AppTheme.bodyTextSmall.copyWith(
                        color: AppTheme.darkBlue,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedSeverity = 'All';
                        _selectedTimeFilter = 'All';
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          
          // Alerts list
          Expanded(
            child: filteredAlerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No alerts found',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: AppTheme.bodyText.copyWith(
                            color: AppTheme.darkGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = filteredAlerts[index];
                      Color severityColor;
                      
                      switch (alert.severity.toLowerCase()) {
                        case 'low':
                          severityColor = AppTheme.successGreen;
                          break;
                        case 'medium':
                          severityColor = Theme.of(context).extension<CustomColors>()?.warning ?? AppTheme.warningOrange;
                          break;
                        case 'high':
                        case 'critical':
                          severityColor = AppTheme.errorRed;
                          break;
                        default:
                          severityColor = AppTheme.mediumGray;
                      }
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AlertDetailScreen(alert: alert),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(severityColor.red, severityColor.green, severityColor.blue, 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.warning,
                                        color: severityColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            alert.severity,
                                            style: AppTheme.headingSmall.copyWith(
                                              color: severityColor,
                                            ),
                                          ),
                                          Text(
                                            _getTimeAgo(alert.timestamp),
                                            style: AppTheme.bodyTextSmall.copyWith(
                                              color: AppTheme.darkGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppTheme.mediumGray,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  alert.description,
                                  style: AppTheme.bodyText.copyWith(
                                    color: AppTheme.darkBlue,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: AppTheme.mediumGray,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reported by ${alert.reportedBy}',
                                      style: AppTheme.bodyTextSmall.copyWith(
                                        color: AppTheme.darkGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 