import 'package:flutter/material.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:cursortest/widgets/custom_toast.dart';
import 'package:cursortest/screens/report_form_screen.dart';
import 'package:cursortest/screens/report_debug_screen.dart';

class ReportSuccessScreen extends StatelessWidget {
  final String? warningMessage;
  const ReportSuccessScreen({super.key, this.warningMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.accentWhite,
      body: Stack(
        children: [
          // Floating X button at top right
          Positioned(
            top: 24,
            right: 24,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close, size: 28),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                splashRadius: 24,
              ),
            ),
          ),
          // Centered card content
          Center(
            child: Card(
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.successGreen, size: 64),
                    const SizedBox(height: 16),
                    Text('Report Submitted', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Thank you for reporting this flood. Your information will help keep others safe.\n\nYour report has been received and will be reviewed by our team. Emergency services will be notified if necessary.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const ReportFormScreen()),
                        );
                      },
                      child: Text('Submit another report'),
                    ),
                    const SizedBox(height: 16),
                    // Developer-only debug button
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ReportDebugScreen()),
                        );
                      },
                      icon: const Icon(Icons.bug_report, size: 18),
                      label: const Text('Debug Reports'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[400]!),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Persistent warning at the bottom
          if (warningMessage != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomToast(
                  message: warningMessage!,
                  type: ToastType.warning,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 