import 'package:flutter/material.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:cursortest/services/geofencing_service.dart';
import 'package:cursortest/services/background_service.dart';
import 'package:cursortest/models/geofence_region.dart';

class GeofenceSettingsScreen extends StatefulWidget {
  const GeofenceSettingsScreen({super.key});

  @override
  State<GeofenceSettingsScreen> createState() => _GeofenceSettingsScreenState();
}

class _GeofenceSettingsScreenState extends State<GeofenceSettingsScreen> {
  final GeofencingService _geofencingService = GeofencingService();
  final BackgroundService _backgroundService = BackgroundService();
  bool _notificationsEnabled = true;
  double _notificationRadius = 1000;
  List<GeofenceRegion> _regions = [];
  bool _isLoading = true;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    // Load user preferences
    _notificationsEnabled = _geofencingService.notificationsEnabled;
    _notificationRadius = _geofencingService.notificationRadius;
    
    // Load geofence regions
    _regions = _geofencingService.regions;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    await _geofencingService.setNotificationsEnabled(value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _updateNotificationRadius(double value) async {
    await _geofencingService.setNotificationRadius(value);
    setState(() {
      _notificationRadius = value;
    });
  }

  Future<void> _toggleMonitoring() async {
    setState(() {
      _isLoading = true;
    });

    if (_isMonitoring) {
      // Stop monitoring
      await _geofencingService.stopMonitoring();
      await _backgroundService.stopGeofencing();
    } else {
      // Start monitoring
      await _geofencingService.startMonitoring();
      await _backgroundService.startGeofencing();
    }

    setState(() {
      _isMonitoring = !_isMonitoring;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMonitoring 
          ? 'Location monitoring is active' 
          : 'Location monitoring is inactive'),
        backgroundColor: _isMonitoring 
          ? AppTheme.successGreen 
          : AppTheme.mediumGray,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.accentWhite,
      appBar: AppBar(
        title: Text(
          'Geofence Settings',
          style: AppTheme.headingMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryBlue,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification settings
                    Text(
                      'Notification Settings',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: Text(
                                'Enable Notifications',
                                style: AppTheme.bodyText.copyWith(
                                  color: AppTheme.darkBlue,
                                ),
                              ),
                              subtitle: Text(
                                'Receive alerts when entering flood-prone areas',
                                style: AppTheme.bodyTextSmall.copyWith(
                                  color: AppTheme.darkGray,
                                ),
                              ),
                              value: _notificationsEnabled,
                              onChanged: _toggleNotifications,
                              activeColor: AppTheme.primaryBlue,
                            ),
                            const Divider(),
                            ListTile(
                              title: Text(
                                'Notification Radius',
                                style: AppTheme.bodyText.copyWith(
                                  color: AppTheme.darkBlue,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_notificationRadius.round()} meters',
                                    style: AppTheme.bodyTextSmall.copyWith(
                                      color: AppTheme.darkGray,
                                    ),
                                  ),
                                  Slider(
                                    value: _notificationRadius,
                                    min: 100,
                                    max: 5000,
                                    divisions: 49,
                                    label: '${_notificationRadius.round()} meters',
                                    onChanged: _updateNotificationRadius,
                                    activeColor: AppTheme.primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Geofence regions
                    Text(
                      'Flood-Prone Areas',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _regions.map((region) {
                          return _buildRegionTile(region);
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Start/Stop monitoring
                    ElevatedButton(
                      onPressed: _isLoading ? null : _toggleMonitoring,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMonitoring 
                          ? AppTheme.errorRed 
                          : AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isMonitoring 
                              ? 'Stop Location Monitoring' 
                              : 'Start Location Monitoring'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Monitoring status
                    if (_isMonitoring)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(AppTheme.successGreen.red, AppTheme.successGreen.green, AppTheme.successGreen.blue, 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color.fromRGBO(AppTheme.successGreen.red, AppTheme.successGreen.green, AppTheme.successGreen.blue, 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.successGreen,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Location monitoring is active. You will receive notifications when entering flood-prone areas.',
                                style: AppTheme.bodyTextSmall.copyWith(
                                  color: AppTheme.darkBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRegionTile(GeofenceRegion region) {
    Color severityColor;
    
    switch (region.severity.toLowerCase()) {
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
    
    return ListTile(
      title: Text(
        region.name,
        style: AppTheme.bodyText.copyWith(
          color: AppTheme.darkBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            region.description,
            style: AppTheme.bodyTextSmall.copyWith(
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Radius: ${region.radius} meters',
            style: AppTheme.bodyTextSmall.copyWith(
              color: AppTheme.darkGray,
            ),
          ),
        ],
      ),
      leading: Container(
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
      trailing: Text(
        region.severity,
        style: AppTheme.bodyTextSmall.copyWith(
          color: severityColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 