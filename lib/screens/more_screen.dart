import 'package:flutter/material.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:cursortest/screens/privacy_disclaimer_screen.dart';
import 'package:cursortest/screens/geofence_settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.accentWhite,
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // How It Works section
            _buildSectionHeader('How It Works'),
            _buildInfoCard(
              title: 'Crowdsourced Flood Alerts',
              description: 'Our app uses community reports to create a real-time map of flood conditions. Users can report floods, view alerts, and stay informed about dangerous areas.',
              icon: Icons.info_outline,
            ),
            _buildInfoCard(
              title: 'Report Submission',
              description: 'When you encounter a flood, you can submit a report with details about the location, severity, and photos. This helps others avoid dangerous areas.',
              icon: Icons.add_alert,
            ),
            _buildInfoCard(
              title: 'Alert System',
              description: 'The app notifies users about flood alerts in their area. You can customize notification settings to receive alerts based on severity and distance.',
              icon: Icons.notifications,
            ),
            const SizedBox(height: 24),
            
            // Safety Tips section
            _buildSectionHeader('Safety Tips'),
            _buildInfoCard(
              title: 'During a Flood',
              description: 'Move to higher ground immediately. Do not walk, swim, or drive through flood waters. Just 6 inches of moving water can knock you down, and 1 foot of water can sweep your vehicle away.',
              icon: Icons.warning,
            ),
            _buildInfoCard(
              title: 'Emergency Preparedness',
              description: 'Keep an emergency kit ready with food, water, flashlights, and a first aid kit. Know your evacuation routes and have a family communication plan.',
              icon: Icons.emergency,
            ),
            _buildInfoCard(
              title: 'After a Flood',
              description: 'Return home only when authorities say it is safe. Be aware of areas where flood waters have receded and watch out for debris. Do not drink tap water until it has been declared safe.',
              icon: Icons.health_and_safety,
            ),
            const SizedBox(height: 24),
            
            // Settings section
            _buildSectionHeader('Settings'),
            _buildInfoCard(
              title: 'Geofence Alerts',
              description: 'Configure location-based alerts for flood-prone areas. Receive notifications when you enter high-risk zones.',
              icon: Icons.location_on,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GeofenceSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // FAQs section
            _buildSectionHeader('Frequently Asked Questions'),
            _buildExpandableCard(
              title: 'How accurate are the flood reports?',
              content: 'Flood reports are submitted by community members and verified when possible. While we strive for accuracy, always exercise caution and follow official guidance during emergencies.',
            ),
            _buildExpandableCard(
              title: 'Can I report a flood anonymously?',
              content: 'Yes, you can submit reports without revealing your identity. However, providing contact information helps us verify reports and contact you for more details if needed.',
            ),
            _buildExpandableCard(
              title: 'How often is the map updated?',
              content: 'The map updates in real-time as new reports are submitted. You can refresh the map manually or enable automatic updates in the settings.',
            ),
            _buildExpandableCard(
              title: 'Is the app available offline?',
              content: 'Basic functionality is available offline, but you need an internet connection to submit reports, view the latest alerts, and update the map.',
            ),
            const SizedBox(height: 24),
            
            // App Info section
            _buildSectionHeader('App Info'),
            _buildInfoCard(
              title: 'Version',
              description: '1.0.0',
              icon: Icons.info,
            ),
            _buildInfoCard(
              title: 'Privacy Policy',
              description: 'We collect location data to provide flood alerts and improve our service. Your data is stored securely and never shared with third parties without your consent.',
              icon: Icons.privacy_tip,
              onTap: () {
                // TODO: Navigate to privacy policy
              },
            ),
            _buildInfoCard(
              title: 'Terms of Service',
              description: 'By using this app, you agree to our terms of service. The app is provided "as is" without warranties of any kind.',
              icon: Icons.description,
              onTap: () {
                // TODO: Navigate to terms of service
              },
            ),
            _buildInfoCard(
              title: 'Location Data Disclaimer',
              description: 'This app collects location data to provide flood alerts and improve our service. Your location is only used when you submit a report or enable location-based alerts.',
              icon: Icons.location_on,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PrivacyDisclaimerScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Contact section
            _buildSectionHeader('Contact Us'),
            _buildInfoCard(
              title: 'Email',
              description: 'support@floodalert.com',
              icon: Icons.email,
              onTap: () {
                // TODO: Open email client
              },
            ),
            _buildInfoCard(
              title: 'Website',
              description: 'www.floodalert.com',
              icon: Icons.language,
              onTap: () {
                // TODO: Open website
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: AppTheme.headingMedium,
      ),
    );
  }
  
  Widget _buildInfoCard({
    required String title,
    required String description,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.headingSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTheme.bodyText,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildExpandableCard({
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        title: Text(
          title,
          style: AppTheme.headingSmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: Text(
              content,
              style: AppTheme.bodyText,
            ),
          ),
        ],
      ),
    );
  }
} 