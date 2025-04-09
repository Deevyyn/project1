import 'package:flutter/material.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:cursortest/models/flood_alert.dart';
import 'package:intl/intl.dart';

class AlertDetailScreen extends StatelessWidget {
  final FloodAlert alert;

  const AlertDetailScreen({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    // Format the timestamp
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final formattedDate = dateFormat.format(alert.timestamp);
    final formattedTime = timeFormat.format(alert.timestamp);
    
    // Determine severity color
    Color severityColor;
    String severityIcon;
    String safetyAdvice;
    
    switch (alert.severity.toLowerCase()) {
      case 'low':
        severityColor = AppTheme.successGreen;
        severityIcon = '⚠️';
        safetyAdvice = 'Stay informed about the situation. Avoid unnecessary travel in affected areas.';
        break;
      case 'medium':
        severityColor = Theme.of(context).extension<CustomColors>()?.warning ?? AppTheme.warningOrange;
        severityIcon = '⚠️⚠️';
        safetyAdvice = 'Avoid flooded areas. Do not attempt to walk or drive through floodwaters. Move to higher ground if necessary.';
        break;
      case 'high':
        severityColor = AppTheme.errorRed;
        severityIcon = '⚠️⚠️⚠️';
        safetyAdvice = 'Immediate action required. Move to higher ground immediately. Do not return to affected areas until authorities give the all-clear.';
        break;
      case 'critical':
        severityColor = AppTheme.errorRed;
        severityIcon = '⚠️⚠️⚠️⚠️';
        safetyAdvice = 'EMERGENCY: Evacuate immediately if advised. Do not delay. Follow emergency services instructions.';
        break;
      default:
        severityColor = AppTheme.mediumGray;
        severityIcon = '⚠️';
        safetyAdvice = 'Stay informed about the situation.';
    }
    
    return Scaffold(
      backgroundColor: AppTheme.accentWhite,
      appBar: AppBar(
        title: Text(
          'Alert Details',
          style: AppTheme.headingMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert header with severity indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color.fromRGBO(severityColor.red, severityColor.green, severityColor.blue, 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Color.fromRGBO(severityColor.red, severityColor.green, severityColor.blue, 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(severityColor.red, severityColor.green, severityColor.blue, 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          severityIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Severity: ${alert.severity}',
                              style: AppTheme.headingSmall.copyWith(
                                color: severityColor,
                              ),
                            ),
                            Text(
                              'Reported on $formattedDate at $formattedTime',
                              style: AppTheme.bodyTextSmall.copyWith(
                                color: AppTheme.darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Safety Advice:',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    safetyAdvice,
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ],
              ),
            ),
            
            // Alert details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Information',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Coordinates',
                    value: '${alert.latitude.toStringAsFixed(6)}, ${alert.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Alert Details',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'Reported By',
                    value: alert.reportedBy,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Description',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color.fromRGBO(AppTheme.mediumGray.red, AppTheme.mediumGray.green, AppTheme.mediumGray.blue, 0.5),
                      ),
                    ),
                    child: Text(
                      alert.description,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.darkBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Image if available
            if (alert.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alert Image',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        alert.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: Color.fromRGBO(AppTheme.mediumGray.red, AppTheme.mediumGray.green, AppTheme.mediumGray.blue, 0.2),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            
            // Emergency contacts
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Contacts',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildEmergencyContact(
                    icon: Icons.emergency,
                    title: 'Emergency Services',
                    number: '911',
                    description: 'For immediate life-threatening emergencies',
                  ),
                  const SizedBox(height: 12),
                  _buildEmergencyContact(
                    icon: Icons.local_hospital,
                    title: 'Flood Emergency Hotline',
                    number: '1-800-FLOOD-HELP',
                    description: '24/7 flood emergency assistance',
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement share functionality
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share Alert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement report issue functionality
                    },
                    icon: const Icon(Icons.flag),
                    label: const Text('Report Issue'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyTextSmall.copyWith(
                    color: AppTheme.darkGray,
                  ),
                ),
                Text(
                  value,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmergencyContact({
    required IconData icon,
    required String title,
    required String number,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color.fromRGBO(AppTheme.mediumGray.red, AppTheme.mediumGray.green, AppTheme.mediumGray.blue, 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.fromRGBO(AppTheme.primaryBlue.red, AppTheme.primaryBlue.green, AppTheme.primaryBlue.blue, 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
                Text(
                  number,
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                ),
                Text(
                  description,
                  style: AppTheme.bodyTextSmall.copyWith(
                    color: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 