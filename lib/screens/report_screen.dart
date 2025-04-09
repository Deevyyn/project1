import 'package:flutter/material.dart';
import 'package:cursortest/widgets/weather_widget.dart';
import 'package:cursortest/models/weather_data.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:cursortest/screens/report_form_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.accentWhite,
      appBar: AppBar(
        title: const Text('Report'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weather widget
            WeatherWidget(
              weatherData: WeatherData.defaultData(),
            ),
            
            // Report section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.add_alert,
                        size: 64,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Report a Flood',
                        style: AppTheme.headingLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Help others by reporting flood conditions in your area',
                        style: AppTheme.bodyText,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ReportFormScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Report Flood'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: AppTheme.accentWhite,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Safety tips section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: AppTheme.errorRed,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Safety Tips',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSafetyTip(
                        'Move to higher ground immediately',
                        'Do not walk, swim, or drive through flood waters',
                      ),
                      _buildSafetyTip(
                        'Stay informed',
                        'Listen to local news and weather reports for updates',
                      ),
                      _buildSafetyTip(
                        'Avoid contact with flood water',
                        'It may be contaminated with sewage or hazardous materials',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSafetyTip(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppTheme.successGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
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