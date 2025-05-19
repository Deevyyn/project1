import 'package:flutter/material.dart';
import 'package:cursortest/models/weather_data.dart';
import 'package:cursortest/services/weather_service.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:intl/intl.dart';

class WeatherWidget extends StatefulWidget {
  final WeatherData weatherData;
  final bool showForecast;

  const WeatherWidget({
    required this.weatherData,
    this.showForecast = true,
    super.key,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final WeatherService _weatherService = WeatherService();
  List<WeatherData> _forecastData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadForecastData();
  }

  Future<void> _loadForecastData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load forecast data
      final forecastData = await _weatherService.getWeatherForecast();
      
      if (mounted) {
        setState(() {
          _forecastData = forecastData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load forecast data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage != null
              ? _buildErrorMessage()
              : _buildWeatherContent(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
            _errorMessage!,
            textAlign: TextAlign.center,
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.errorRed,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadForecastData,
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

  Widget _buildWeatherContent() {
    final risk = _weatherService.calculateFloodRisk(widget.weatherData);
    final riskColor = _weatherService.getRiskLevelColor(risk);
    final riskDescription = _weatherService.getRiskLevelDescription(risk);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with refresh button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Weather',
                style: AppTheme.headingSmall.copyWith(
                  color: AppTheme.primaryBlue,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                color: AppTheme.primaryBlue,
                onPressed: _loadForecastData,
              ),
            ],
          ),
        ),
        
        // Current weather details
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Weather icon
              Image.network(
                widget.weatherData.getWeatherIconUrl(),
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.wb_sunny,
                    size: 80,
                    color: AppTheme.primaryBlue,
                  );
                },
              ),
              
              const SizedBox(width: 16),
              
              // Temperature and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.weatherData.temperature.round()}°C',
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      widget.weatherData.description,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.secondaryBlue,
                      ),
                    ),
                    Text(
                      'Feels like ${widget.weatherData.feelsLike.round()}°C',
                      style: AppTheme.bodyTextSmall.copyWith(
                        color: AppTheme.secondaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const Divider(),
        
        // Additional weather details
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(
                Icons.water_drop,
                '${(widget.weatherData.humidity * 100).round()}%',
                'Humidity',
              ),
              _buildWeatherDetail(
                Icons.air,
                '${widget.weatherData.windSpeed.toStringAsFixed(1)} m/s',
                'Wind',
              ),
              _buildWeatherDetail(
                Icons.water,
                '${widget.weatherData.rainfall.toStringAsFixed(1)} mm',
                'Rainfall',
              ),
              _buildWeatherDetail(
                Icons.visibility,
                '${(widget.weatherData.visibility / 1000).round()} km',
                'Visibility',
              ),
            ],
          ),
        ),
        
        const Divider(),
        
        // Flood risk and rain intensity indicator
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flood risk row
              Text(
                'Flood Risk',
                style: AppTheme.headingSmall.copyWith(
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: riskColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${(risk * 100).round()}%',
                        style: AppTheme.bodyTextSmall.copyWith(
                          color: AppTheme.accentWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    riskDescription,
                    style: AppTheme.bodyText.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Rain intensity row
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.speed,
                    size: 20,
                    color: AppTheme.secondaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rain Intensity: ${widget.weatherData.rainIntensity.toStringAsFixed(1)} mm/h',
                    style: AppTheme.bodyTextSmall.copyWith(
                      color: AppTheme.secondaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Forecast preview (if enabled and available)
        if (widget.showForecast && _forecastData.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forecast',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _forecastData.length,
                    itemBuilder: (context, index) {
                      final forecast = _forecastData[index];
                      return _buildForecastItem(forecast);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return SizedBox(
      width: 70, // Fixed width for consistent spacing
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTheme.bodyTextSmall.copyWith(
              color: AppTheme.secondaryBlue,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildForecastItem(WeatherData forecast) {
    final dateFormat = DateFormat('EEE');
    final dayName = dateFormat.format(forecast.timestamp);
    
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Text(
            dayName,
            style: AppTheme.bodyTextSmall.copyWith(
              color: AppTheme.secondaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Image.network(
            forecast.getWeatherIconUrl(),
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.wb_sunny,
                size: 40,
                color: AppTheme.primaryBlue,
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            '${forecast.temperature.round()}°',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 