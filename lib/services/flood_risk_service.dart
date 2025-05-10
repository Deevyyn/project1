import 'package:cursortest/services/weather_service.dart';
import 'package:cursortest/models/weather_data.dart';

class FloodRiskService {
  static final FloodRiskService _instance = FloodRiskService._internal();
  factory FloodRiskService() => _instance;
  FloodRiskService._internal();

  final WeatherService _weatherService = WeatherService();

  /// Calculates flood risk level based on current weather data and other factors
  /// 
  /// [latitude] - Location latitude
  /// [longitude] - Location longitude
  /// [elevation] - Location elevation in meters
  /// [userReports] - Number of validated flood reports from the same region
  /// [scpRiskLevel] - SCP risk level ("Above Normal", "Normal", or "Below Normal")
  /// [hasHistoricalFloodData] - Whether the region has historical flood data
  /// 
  /// Returns a risk level as a String: "Low", "Medium", or "High"
  Future<String> calculateFloodRisk({
    required double latitude,
    required double longitude,
    required double elevation,
    required int userReports,
    required String scpRiskLevel,
    required bool hasHistoricalFloodData,
  }) async {
    try {
      // Get current weather data for the location
      final weatherData = await _weatherService.getWeatherForLocation(latitude, longitude);
      
      // If there are more than 2 user reports, override to High risk
      if (userReports > 2) {
        return "High";
      }

      int score = 0;

      // Rainfall scoring based on weather data
      if (weatherData.rainfall > 40) {
        score += 2;
      }

      // Elevation scoring
      if (elevation < 30) {
        score += 2;
      }

      // SCP risk level scoring
      switch (scpRiskLevel) {
        case "Above Normal":
          score += 2;
          break;
        case "Normal":
          score += 1;
          break;
        case "Below Normal":
          // No points added for Below Normal
          break;
        default:
          throw ArgumentError('Invalid SCP risk level: $scpRiskLevel');
      }

      // Historical flood data scoring
      if (hasHistoricalFloodData) {
        score += 1;
      }

      // Additional risk factors from weather data
      if (weatherData.rainIntensity > 10) {
        score += 1; // Heavy rain increases risk
      }
      if (weatherData.humidity > 0.8) {
        score += 1; // High humidity increases risk
      }

      // Determine final risk level based on total score
      if (score >= 6) {
        return "High";
      } else if (score >= 3) {
        return "Medium";
      } else {
        return "Low";
      }
    } catch (e) {
      // In case of error, return a default risk level
      return "Medium";
    }
  }

  /// Gets detailed flood risk information including weather data
  /// 
  /// Returns a map containing:
  /// - riskLevel: The calculated risk level ("Low", "Medium", or "High")
  /// - weatherData: The current weather data
  /// - score: The calculated risk score
  /// - factors: A list of contributing risk factors
  Future<Map<String, dynamic>> getDetailedFloodRisk({
    required double latitude,
    required double longitude,
    required double elevation,
    required int userReports,
    required String scpRiskLevel,
    required bool hasHistoricalFloodData,
  }) async {
    try {
      final weatherData = await _weatherService.getWeatherForLocation(latitude, longitude);
      
      // If there are more than 2 user reports, return High risk immediately
      if (userReports > 2) {
        return {
          'riskLevel': "High",
          'weatherData': weatherData,
          'score': 7, // Override score
          'factors': [
            'High number of user reports (>2)',
            'Current rainfall: ${weatherData.rainfall}mm',
            'Rain intensity: ${weatherData.rainIntensity}mm/h',
            'Elevation: ${elevation}m',
            'SCP Risk Level: $scpRiskLevel',
            'Historical Data: ${hasHistoricalFloodData ? "Available" : "Not Available"}',
          ],
        };
      }

      int score = 0;
      List<String> factors = [];

      // Rainfall scoring
      if (weatherData.rainfall > 40) {
        score += 2;
        factors.add('High rainfall (>40mm)');
      }

      // Elevation scoring
      if (elevation < 30) {
        score += 2;
        factors.add('Low elevation (<30m)');
      }

      // SCP risk level scoring
      switch (scpRiskLevel) {
        case "Above Normal":
          score += 2;
          factors.add('Above Normal SCP risk level');
          break;
        case "Normal":
          score += 1;
          factors.add('Normal SCP risk level');
          break;
        case "Below Normal":
          factors.add('Below Normal SCP risk level');
          break;
      }

      // Historical flood data scoring
      if (hasHistoricalFloodData) {
        score += 1;
        factors.add('Historical flood data available');
      }

      // Additional weather factors
      if (weatherData.rainIntensity > 10) {
        score += 1;
        factors.add('High rain intensity (>10mm/h)');
      }
      if (weatherData.humidity > 0.8) {
        score += 1;
        factors.add('High humidity (>80%)');
      }

      // Determine final risk level
      String riskLevel;
      if (score >= 6) {
        riskLevel = "High";
      } else if (score >= 3) {
        riskLevel = "Medium";
      } else {
        riskLevel = "Low";
      }

      return {
        'riskLevel': riskLevel,
        'weatherData': weatherData,
        'score': score,
        'factors': factors,
      };
    } catch (e) {
      return {
        'riskLevel': "Medium",
        'weatherData': WeatherData.defaultData(),
        'score': 3,
        'factors': ['Error calculating risk: $e'],
      };
    }
  }
} 