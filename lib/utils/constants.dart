class AppConstants {
  static const String appName = 'Flood Alert System';
  
  // API endpoints
  static const String baseUrl = 'https://api.example.com'; // Replace with actual API endpoint
  static const String reportEndpoint = '/reports';
  static const String alertsEndpoint = '/alerts';
  
  // Map settings
  static const double defaultZoom = 13.0;
  static const double defaultLat = 0.0;
  static const double defaultLng = 0.0;
  
  // Alert severity levels
  static const List<String> severityLevels = [
    'Low',
    'Medium',
    'High',
    'Critical'
  ];
  
  // Image settings
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  
  // Location settings
  static const int locationTimeout = 10000; // 10 seconds
  static const double locationAccuracy = 50.0; // meters
} 