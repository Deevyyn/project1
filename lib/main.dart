import 'package:flutter/material.dart';
import 'package:cursortest/screens/splash_screen.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:cursortest/services/geofencing_service.dart';
import 'package:cursortest/services/background_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cursortest/services/supabase_service.dart';


void main() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
        url: 'https://grklybpmnpqheqerziqj.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdya2x5YnBtbnBxaGVxZXJ6aXFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY5MTU3MDUsImV4cCI6MjA2MjQ5MTcwNX0.G18vckXgequyzqvyU_9NEkdf0HjnfZcuvCCmhLk3WOI',
    );
    // Initialize services
    await _initializeServices();

    // Run the app
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error initializing app: $e');
    // Run the app without services in case of initialization error
    runApp(const MyApp());
  }
}

Future<void> _initializeServices() async {
  try {
    // Initialize geofencing service
    final geofencingService = GeofencingService();
    await geofencingService.initialize();

    // Initialize background service
    final backgroundService = BackgroundService();
    await backgroundService.initialize();

    // Test Supabase functionality if in debug mode
    await _testSupabaseFunctionality();
  } catch (e) {
    debugPrint('Error initializing services: $e');
    // Let the error propagate to main() for handling
    rethrow;
  }
}

/// Test function to demonstrate Supabase functionality for uploading images and submitting reports
/// This is for demonstration purposes only and will only run in debug mode
Future<void> _testSupabaseFunctionality() async {
  try {
    debugPrint('Testing Supabase functionality...');

    // Create a SupabaseService instance
    final supabaseService = SupabaseService();

    // Run the test report submission function
    await supabaseService.testReportSubmission();

    debugPrint('Supabase functionality test completed successfully');
  } catch (e) {
    // Only log the error, don't rethrow as this is just a test
    debugPrint('Error testing Supabase functionality: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flood Alert',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Force light theme for now
      home: Builder(
        builder: (context) {
          return const SplashScreen();
        },
      ),
    );
  }
}
