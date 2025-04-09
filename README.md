# Flood Alert App

A Flutter application for reporting and monitoring flood conditions in your area. The app provides real-time weather data, flood risk assessment, and community-based flood reporting.

## Features

- **Weather Integration**: Real-time weather data and forecasts to assess flood risk
- **Flood Reporting**: Submit detailed reports with location, photos, and severity information
- **Alert System**: Receive notifications about flood conditions in your area
- **Safety Information**: Access flood safety tips and emergency contacts
- **Geofencing**: Get alerts when entering flood-prone areas

## Getting Started

### Prerequisites

- Flutter SDK (version 3.1.3 or higher)
- Dart SDK (version 3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/flood_alert.git
   ```

2. Navigate to the project directory:
   ```
   cd flood_alert
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Set up your OpenWeatherMap API key:
   - Sign up for a free API key at [OpenWeatherMap](https://openweathermap.org/api)
   - Open `lib/services/weather_service.dart`
   - Replace `YOUR_OPENWEATHERMAP_API_KEY` with your actual API key

5. Run the app:
   ```
   flutter run
   ```

## Configuration

### OpenWeatherMap API Key

The app uses the OpenWeatherMap API to fetch weather data. You need to:

1. Sign up for a free account at [OpenWeatherMap](https://openweathermap.org/api)
2. Get your API key from your account dashboard
3. Replace the placeholder in `lib/services/weather_service.dart`:
   ```dart
   final String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
   ```

### Geofencing Settings

To enable location-based alerts:

1. Navigate to the "More" screen
2. Tap on "Geofence Settings"
3. Enable notifications and set your preferred notification radius
4. Start location monitoring

## Project Structure

- `lib/models/`: Data models for the application
- `lib/screens/`: UI screens
- `lib/services/`: Backend services for API calls, location, etc.
- `lib/utils/`: Utility functions and theme definitions
- `lib/widgets/`: Reusable UI components

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenWeatherMap for providing weather data
- Flutter team for the amazing framework
- All contributors who have helped with the project
