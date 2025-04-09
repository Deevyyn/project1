import 'package:flutter/material.dart';
import 'package:cursortest/screens/splash_screen.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:cursortest/services/geofencing_service.dart';
import 'package:cursortest/services/background_service.dart';

void main() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();
    
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
  } catch (e) {
    debugPrint('Error initializing services: $e');
    // Let the error propagate to main() for handling
    rethrow;
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
