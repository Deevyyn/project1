import 'package:flutter/material.dart';
import 'package:cursortest/widgets/weather_widget.dart';
import 'package:cursortest/models/weather_data.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:cursortest/screens/report_form_screen.dart';
import 'package:cursortest/services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _currentWeather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weatherData = await _weatherService.getCurrentWeather();
      setState(() {
        _currentWeather = weatherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load weather data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flood Watch'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWeatherData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Weather Widget at the top
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryBlue,
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.errorRed,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: AppTheme.bodyText,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _loadWeatherData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : WeatherWidget(
                            weatherData: _currentWeather!,
                            showForecast: false,
                          ),
              ),

              // Report Flood Button in the middle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportFormScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Report Flood',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Safety Tips at the bottom
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppTheme.accentWhite,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety Tips',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSafetyTip(
                      Icons.warning,
                      'Stay informed about weather conditions and flood warnings',
                    ),
                    _buildSafetyTip(
                      Icons.height,
                      'Avoid walking or driving through flood waters',
                    ),
                    _buildSafetyTip(
                      Icons.home,
                      'Move to higher ground if flooding is imminent',
                    ),
                    _buildSafetyTip(
                      Icons.battery_charging_full,
                      'Keep emergency supplies and important documents ready',
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

  Widget _buildSafetyTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyText.copyWith(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 