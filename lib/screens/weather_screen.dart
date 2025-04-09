import 'package:flutter/material.dart';
import 'package:cursortest/models/weather_data.dart';
import 'package:cursortest/services/weather_service.dart';
import 'package:cursortest/widgets/weather_widget.dart';
import 'package:cursortest/utils/theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _currentWeather;
  List<WeatherData> _forecast = [];
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
      // Load current weather
      final currentWeather = await _weatherService.getCurrentWeather();
      
      // Load forecast
      final forecast = await _weatherService.getWeatherForecast();
      
      setState(() {
        _currentWeather = currentWeather;
        _forecast = forecast;
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
        title: const Text('Weather Information'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.accentWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeatherData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryBlue,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTheme.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWeatherData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: AppTheme.accentWhite,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWeatherData,
      color: AppTheme.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_currentWeather != null) ...[
            WeatherWidget(
              weatherData: _currentWeather!,
              showForecast: true,
            ),
            const SizedBox(height: 24),
            Text(
              '5-Day Forecast',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildForecastList(),
        ],
      ),
    );
  }

  Widget _buildForecastList() {
    if (_forecast.isEmpty) {
      return const Center(
        child: Text(
          'No forecast data available',
          style: AppTheme.bodyText,
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _forecast.length,
        itemBuilder: (context, index) {
          final forecast = _forecast[index];
          return _buildForecastItem(forecast);
        },
      ),
    );
  }

  Widget _buildForecastItem(WeatherData forecast) {
    final date = forecast.timestamp;
    final dayOfWeek = _getDayOfWeek(date.weekday);
    
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.accentWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayOfWeek,
            style: AppTheme.bodyText.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _getWeatherIcon(forecast.weatherCondition),
          const SizedBox(height: 8),
          Text(
            '${forecast.temperature.toStringAsFixed(1)}°C',
            style: AppTheme.bodyText,
          ),
          Text(
            '${forecast.rainIntensity.toStringAsFixed(1)} mm/h',
            style: AppTheme.bodyText.copyWith(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getWeatherIcon(String condition) {
    IconData iconData;
    Color iconColor;
    
    switch (condition.toLowerCase()) {
      case 'storm':
      case 'thunderstorm':
        iconData = Icons.thunderstorm;
        iconColor = AppTheme.errorRed;
        break;
      case 'heavy rain':
        iconData = Icons.water_drop;
        iconColor = AppTheme.primaryBlue;
        break;
      case 'rain':
        iconData = Icons.water;
        iconColor = AppTheme.primaryBlue;
        break;
      case 'light rain':
        iconData = Icons.grain;
        iconColor = AppTheme.primaryBlue;
        break;
      case 'drizzle':
        iconData = Icons.grain;
        iconColor = AppTheme.primaryBlue;
        break;
      case 'clear':
      case 'sunny':
        iconData = Icons.wb_sunny;
        iconColor = AppTheme.warningYellow;
        break;
      default:
        iconData = Icons.cloud;
        iconColor = AppTheme.primaryBlue;
    }
    
    return Icon(
      iconData,
      color: iconColor,
      size: 24,
    );
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
} 