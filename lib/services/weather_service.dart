import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cursortest/models/weather_data.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // OpenWeatherMap API key
  final String _apiKey = '2794f8846afaf71b611aa5341e3fd71e';
  final String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Cache weather data for 15 minutes
  WeatherData? _cachedWeatherData;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 15);
  
  // Default coordinates for Benin City, Nigeria
  static const double defaultLatitude = 6.3350;
  static const double defaultLongitude = 5.6037;
  
  // Get current weather data
  Future<WeatherData> getCurrentWeather() async {
    // Return cached data if available and not expired
    if (_cachedWeatherData != null && _lastFetchTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastFetchTime!) < _cacheDuration) {
        debugPrint('Returning cached weather data');
        return _cachedWeatherData!;
      }
    }
    
    try {
      final weatherData = await _fetchWeatherFromApi(defaultLatitude, defaultLongitude);
      
      // Cache the data in memory
      _cachedWeatherData = weatherData;
      _lastFetchTime = DateTime.now();
      
      return weatherData;
    } catch (e) {
      debugPrint('Error fetching weather data: $e');
      // Return default data in case of error
      return WeatherData.defaultData();
    }
  }
  
  // Get weather forecast for the next few days
  Future<List<WeatherData>> getWeatherForecast() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$defaultLatitude&lon=$defaultLongitude&appid=$_apiKey&units=metric'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['list'];
        
        // Filter to get one forecast per day
        final Map<String, WeatherData> dailyForecasts = {};
        
        for (var item in list) {
          final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dateString = '${date.year}-${date.month}-${date.day}';
          
          // Only keep the first forecast for each day
          if (!dailyForecasts.containsKey(dateString)) {
            dailyForecasts[dateString] = _parseWeatherData(item);
          }
        }
        
        return dailyForecasts.values.take(5).toList();
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching weather forecast: $e');
      // Return empty list in case of error
      return [];
    }
  }
  
  // Get weather data for a specific location
  Future<WeatherData> getWeatherForLocation(double latitude, double longitude) async {
    try {
      return await _fetchWeatherFromApi(latitude, longitude);
    } catch (e) {
      debugPrint('Error fetching weather data for location: $e');
      // Return default data in case of error
      return WeatherData.defaultData();
    }
  }
  
  // Fetch weather data from OpenWeatherMap API
  Future<WeatherData> _fetchWeatherFromApi(double latitude, double longitude) async {
    final url = Uri.parse(
      '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric'
    );
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseWeatherData(data);
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  }
  
  // Parse OpenWeatherMap API response
  WeatherData _parseWeatherData(Map<String, dynamic> data) {
    final main = data['main'];
    final weather = data['weather'][0];
    final wind = data['wind'];
    final rain = data['rain'] ?? {'1h': 0};
    
    // Calculate rain duration (if available in the data)
    double rainDuration = 1.0;
    if (data['rain'] != null) {
      // If we have 3h data, convert to hourly rate
      if (rain['3h'] != null) {
        rainDuration = 3.0;
      }
    }
    
    return WeatherData(
      rainfall: (rain['1h'] ?? rain['3h'] ?? 0).toDouble(),
      rainIntensity: ((rain['1h'] ?? (rain['3h'] ?? 0) / 3) ?? 0).toDouble(),
      rainDuration: rainDuration,
      temperature: (main['temp'] ?? 0).toDouble(),
      humidity: (main['humidity'] ?? 0).toDouble() / 100,
      windSpeed: (wind['speed'] ?? 0).toDouble(),
      weatherCondition: weather['main'].toString().toLowerCase(),
      description: weather['description'] ?? 'N/A',
      feelsLike: (main['feels_like'] ?? 0).toDouble(),
      visibility: (data['visibility'] ?? 0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['dt'] * 1000),
      additionalData: {
        'pressure': main['pressure'],
        'clouds': data['clouds']?['all'],
        'icon': weather['icon'],
      },
    );
  }
  
  // Calculate flood risk based on weather data
  double calculateFloodRisk(WeatherData weatherData) {
    // Base risk factors
    double risk = 0.0;
    
    // Rain intensity is the most significant factor
    if (weatherData.rainIntensity > 0) {
      // Heavy rain (more than 10mm/hour) significantly increases risk
      if (weatherData.rainIntensity > 10) {
        risk += 0.7;
      } 
      // Moderate rain (5-10mm/hour) moderately increases risk
      else if (weatherData.rainIntensity > 5) {
        risk += 0.5;
      } 
      // Light rain (1-5mm/hour) slightly increases risk
      else {
        risk += 0.3;
      }
    }
    
    // Prolonged rain increases risk
    if (weatherData.rainDuration > 6) {
      risk += 0.2;
    }
    
    // High humidity can indicate potential for more rain
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