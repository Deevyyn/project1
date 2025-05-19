import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cursortest/models/weather_data.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // Open-Meteo API endpoint
  final String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  
  // Cache weather data for 15 minutes
  final Map<String, WeatherData> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 15);
  
  // Default coordinates for Benin City, Nigeria
  static const double defaultLatitude = 6.3350;
  static const double defaultLongitude = 5.6037;
  
  // Get current weather data
  Future<WeatherData> getCurrentWeather() async {
    return getWeatherForLocation(defaultLatitude, defaultLongitude);
  }
  
  // Get weather forecast for the next few days
  Future<List<WeatherData>> getWeatherForecast() async {
    try {
      final url = Uri.parse(
        '$_baseUrl?latitude=$defaultLatitude&longitude=$defaultLongitude'
        '&hourly=precipitation,rain,showers,snowfall,weather_code,temperature_2m,relative_humidity_2m,wind_speed_10m,visibility,apparent_temperature'
        '&timezone=auto&forecast_days=7'
      );
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hourly = data['hourly'] as Map<String, dynamic>;
        final timeList = (hourly['time'] as List).cast<String>();
        
        // Group by day
        final Map<String, List<int>> dailyIndices = {};
        
        for (int i = 0; i < timeList.length; i++) {
          final date = timeList[i].substring(0, 10); // Extract YYYY-MM-DD
          dailyIndices.putIfAbsent(date, () => []).add(i);
        }
        
        // Take one sample per day (midday)
        final forecast = dailyIndices.values
            .map((indices) {
              final midIndex = indices.length ~/ 2;
              return _parseHourlyData(hourly, indices[midIndex]);
            })
            .where((data) => data != null)
            .cast<WeatherData>()
            .toList();
            
        return forecast.take(5).toList();
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching weather forecast: $e');
      return [];
    }
  }
  
  // Get weather data for a specific location
  Future<WeatherData> getWeatherForLocation(double latitude, double longitude) async {
    final cacheKey = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    final now = DateTime.now();
    
    // Return cached data if available and not expired
    if (_cache.containsKey(cacheKey)) {
      final cachedData = _cache[cacheKey]!;
      if (now.difference(cachedData.timestamp) < _cacheDuration) {
        debugPrint('Returning cached weather data for $cacheKey');
        return cachedData;
      }
    }
    
    try {
      final weatherData = await _fetchWeatherFromApi(latitude, longitude);
      _cache[cacheKey] = weatherData;
      return weatherData;
    } catch (e) {
      debugPrint('Error fetching weather data for location: $e');
      // Return default data in case of error
      return WeatherData.defaultData();
    }
  }
  
  // Fetch weather data from Open-Meteo API
  Future<WeatherData> _fetchWeatherFromApi(double latitude, double longitude) async {
    try {
      debugPrint('Fetching weather data for coordinates: ($latitude, $longitude)');
      
      final url = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude'
        '&current=precipitation,rain,showers,snowfall,weather_code,temperature_2m,relative_humidity_2m,wind_speed_10m,visibility,apparent_temperature'
        '&hourly=precipitation,rain,showers,snowfall,weather_code'
        '&timezone=auto&forecast_days=1'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      debugPrint('Weather API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Successfully fetched weather data');
        return _parseWeatherData(data);
      } else {
        debugPrint('Failed to load weather data: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in _fetchWeatherFromApi: $e');
      rethrow;
    }
  }
  
  // Parse Open-Meteo API response
  WeatherData _parseWeatherData(Map<String, dynamic> data) {
    try {
      debugPrint('Parsing weather data...');
      debugPrint('Raw weather data: $data');
      
      final current = data['current'] as Map<String, dynamic>? ?? {};
      debugPrint('Current weather data: $current');
      
      // Get all possible precipitation fields
      final precipitation = (current['precipitation'] ?? 0).toDouble();
      final rain = (current['rain'] ?? 0).toDouble();
      final showers = (current['showers'] ?? 0).toDouble();
      final rain1h = (current['rain_1h'] ?? 0).toDouble();
      final precipitation1h = (current['precipitation_1h'] ?? 0).toDouble();
      
      debugPrint('Precipitation values - precipitation: $precipitation, rain: $rain, showers: $showers, rain_1h: $rain1h, precipitation_1h: $precipitation1h');
      
      // Use the highest precipitation value as rainfall
      final rainfall = [precipitation, rain, showers, rain1h, precipitation1h]
          .reduce((a, b) => a > b ? a : b);
      
      debugPrint('Selected rainfall value: $rainfall');
      
      // Get weather condition from weather code
      final weatherCode = current['weather_code']?.toInt() ?? 0;
      final weatherCondition = _getWeatherCondition(weatherCode);
      debugPrint('Weather code: $weatherCode, Condition: $weatherCondition');
      
      final weatherData = WeatherData(
        rainfall: rainfall > 0 ? rainfall : 0.0, // Ensure non-negative
        rainIntensity: rainfall > 0 ? rainfall : 0.0, // Using same as intensity for now
        rainDuration: rainfall > 0 ? 1.0 : 0.0, // Only set duration if there's rain
        temperature: (current['temperature_2m'] ?? 0).toDouble(),
        humidity: (current['relative_humidity_2m'] ?? 0).toDouble() / 100,
        windSpeed: (current['wind_speed_10m'] ?? 0).toDouble(),
        weatherCondition: weatherCondition,
        description: _getWeatherDescription(weatherCode),
        feelsLike: (current['apparent_temperature'] ?? current['temperature_2m'] ?? 0).toDouble(),
        visibility: (current['visibility'] ?? 10000).toDouble(),
        timestamp: DateTime.now(),
        additionalData: {
          'weather_code': weatherCode,
          'precipitation': precipitation,
          'rain': rain,
          'showers': showers,
        },
      );
      
      debugPrint('Successfully parsed WeatherData');
      return weatherData;
      
    } catch (e, stackTrace) {
      debugPrint('Error parsing weather data: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Falling back to default weather data');
      return WeatherData.defaultData();
    }
  }
  
  // Helper to parse hourly data for forecasts
  WeatherData? _parseHourlyData(Map<String, dynamic> hourly, int index) {
    try {
      final time = (hourly['time'] as List)[index] as String;
      final precipitation = (hourly['precipitation'] as List)[index] as num;
      final rain = (hourly['rain'] as List)[index] as num;
      final showers = (hourly['showers'] as List)[index] as num;
      final weatherCode = (hourly['weather_code'] as List)[index] as int;
      
      return WeatherData(
        rainfall: [precipitation.toDouble(), rain.toDouble(), showers.toDouble()].reduce((a, b) => a > b ? a : b),
        rainIntensity: rain.toDouble(),
        rainDuration: 1.0,
        temperature: 0, // Not available in this view
        humidity: 0,
        windSpeed: 0,
        weatherCondition: _getWeatherCondition(weatherCode),
        description: _getWeatherDescription(weatherCode),
        feelsLike: 0,
        visibility: 10000,
        timestamp: DateTime.parse(time),
        additionalData: {
          'weather_code': weatherCode,
        },
      );
    } catch (e) {
      debugPrint('Error parsing hourly data: $e');
      return null;
    }
  }
  
  // Map WMO weather code to condition string
  String _getWeatherCondition(int code) {
    // WMO Weather interpretation codes (https://open-meteo.com/en/docs)
    if (code >= 95) return 'thunderstorm';
    if (code >= 85) return 'snow';
    if (code >= 71) return 'snow';
    if (code >= 61) return 'rain';
    if (code >= 51) return 'drizzle';
    if (code >= 45) return 'fog';
    if (code >= 3) return 'cloudy';
    if (code >= 1) return 'partly_cloudy';
    return 'clear';
  }
  
  // Map WMO weather code to description
  String _getWeatherDescription(int code) {
    // WMO Weather interpretation codes (https://open-meteo.com/en/docs)
    final descriptions = {
      0: 'Clear sky',
      1: 'Mainly clear',
      2: 'Partly cloudy',
      3: 'Overcast',
      45: 'Fog',
      48: 'Depositing rime fog',
      51: 'Light drizzle',
      53: 'Moderate drizzle',
      55: 'Dense drizzle',
      56: 'Light freezing drizzle',
      57: 'Dense freezing drizzle',
      61: 'Slight rain',
      63: 'Moderate rain',
      65: 'Heavy rain',
      66: 'Light freezing rain',
      67: 'Heavy freezing rain',
      71: 'Slight snow fall',
      73: 'Moderate snow fall',
      75: 'Heavy snow fall',
      77: 'Snow grains',
      80: 'Slight rain showers',
      81: 'Moderate rain showers',
      82: 'Violent rain showers',
      85: 'Slight snow showers',
      86: 'Heavy snow showers',
      95: 'Thunderstorm',
      96: 'Thunderstorm with slight hail',
      99: 'Thunderstorm with heavy hail',
    };
    
    return descriptions[code] ?? 'Unknown weather';
  }
  
  // Calculate flood risk based on weather data
  double calculateFloodRisk(WeatherData weatherData) {
    // Base risk factors
    double risk = 0.0;
    
    // Get additional data from Open-Meteo
    final weatherCode = weatherData.additionalData?['weather_code'] as int? ?? 0;
    final precipitation = weatherData.additionalData?['precipitation']?.toDouble() ?? 0.0;
    final showers = weatherData.additionalData?['showers']?.toDouble() ?? 0.0;
    
    // Rain intensity is the most significant factor
    if (weatherData.rainIntensity > 0) {
      // Very heavy rain (> 20mm/hour) - extremely high risk
      if (weatherData.rainIntensity > 20) {
        risk += 0.8;
      } 
      // Heavy rain (10-20mm/hour) - high risk
      else if (weatherData.rainIntensity > 10) {
        risk += 0.6;
      }
      // Moderate rain (5-10mm/hour) - medium risk
      else if (weatherData.rainIntensity > 5) {
        risk += 0.4;
      } 
      // Light rain (1-5mm/hour) - low risk
      else {
        risk += 0.2;
      }
    }
    
    // Add risk based on precipitation type and amount
    if (precipitation > 0) {
      // Thunderstorms significantly increase risk
      if (weatherCode >= 95) {
        risk += 0.3;
      }
      // Heavy showers increase risk more than light rain
      if (showers > 5) {
        risk += 0.2;
      } else if (showers > 2) {
        risk += 0.1;
      }
    }
    
    // High humidity (>80%) can indicate potential for more rain
    if (weatherData.humidity > 0.8) {
      risk += 0.1;
    }
    
    // Low temperature can indicate frozen ground, which increases runoff
    if (weatherData.temperature < 5) {
      risk += 0.1;
    }
    
    // Cap the risk at 1.0 (100%)
    return risk.clamp(0.0, 1.0);
  }
  
  // Get risk level description
  String getRiskLevelDescription(double risk) {
    if (risk >= 0.8) {
      return 'Critical';
    } else if (risk >= 0.6) {
      return 'High';
    } else if (risk >= 0.4) {
      return 'Medium';
    } else if (risk >= 0.2) {
      return 'Low';
    } else {
      return 'Minimal';
    }
  }
  
  // Get risk level color
  Color getRiskLevelColor(double risk) {
    if (risk >= 0.8) {
      return const Color(0xFFF44336); // Red
    } else if (risk >= 0.6) {
      return const Color(0xFFFF9800); // Orange
    } else if (risk >= 0.4) {
      return const Color(0xFFFFC107); // Yellow
    } else if (risk >= 0.2) {
      return const Color(0xFF4CAF50); // Green
    } else {
      return const Color(0xFF2196F3); // Blue
    }
  }
} 