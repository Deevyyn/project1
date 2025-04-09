import 'package:flutter/material.dart';
import 'package:cursortest/utils/theme.dart';

class PrivacyDisclaimerScreen extends StatelessWidget {
  const PrivacyDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Location Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Data Collection',
              style: AppTheme.headingLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'The Flood Alert app collects location data to provide you with accurate flood alerts and improve our service. This document explains how we use your location data and your rights regarding this information.',
              style: AppTheme.bodyText,
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              title: 'What Location Data We Collect',
              content: [
                'Your current location when you submit a flood report',
                'Your location when you enable location-based alerts',
                'Approximate location data for app functionality',
                'Location history for saved reports (if enabled)',
              ],
            ),
            
            _buildSection(
              title: 'How We Use Your Location Data',
              content: [
                'To display your position on the map',
                'To provide flood alerts relevant to your location',
                'To improve the accuracy of flood reporting',
                'To analyze flood patterns and improve our service',
              ],
            ),
            
            _buildSection(
              title: 'Data Storage and Security',
              content: [
                'Location data is stored securely on our servers',
                'We use encryption to protect your data',
                'Access to your location data is restricted to authorized personnel',
                'We regularly review our security measures to ensure your data is protected',
              ],
            ),
            
            _buildSection(
              title: 'Data Sharing',
              content: [
                'We do not sell your location data to third parties',
                'We may share anonymized, aggregated data for research purposes',
                'We may share your data if required by law',
                'We may share your data with emergency services if necessary for public safety',
              ],
            ),
            
            _buildSection(
              title: 'Your Rights',
              content: [
                'You can disable location services in your device settings',
                'You can opt out of location-based alerts in the app settings',
                'You can request a copy of your location data',
                'You can request deletion of your location data',
              ],
            ),
            
            const SizedBox(height: 24),
            const Text(
              'By using the Flood Alert app, you consent to the collection and use of your location data as described in this document. If you have any questions or concerns about our location data practices, please contact us at privacy@floodalert.com.',
              style: AppTheme.bodyText,
            ),
            const SizedBox(height: 32),
            
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('I Understand'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required List<String> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.headingMedium,
        ),
        const SizedBox(height: 8),
        ...content.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  item,
                  style: AppTheme.bodyText,
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
} 