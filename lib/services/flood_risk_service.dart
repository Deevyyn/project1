import 'dart:developer';

import 'package:cursortest/models/weather_data.dart';
import 'package:cursortest/services/weather_service.dart';

class FloodRiskService {
  static final FloodRiskService _instance = FloodRiskService._internal();
  factory FloodRiskService() => _instance;
  FloodRiskService._internal();

  final WeatherService _weatherService = WeatherService();
  
  // Risk level thresholds
  static const int highRiskThreshold = 6;
  static const int mediumRiskThreshold = 3;
  
  // Scoring weights
  static const int rainfallWeight = 2;
  static const int elevationWeight = 2;
  static const int scpAboveNormalWeight = 2;
  static const int scpNormalWeight = 1;
  static const int rainIntensityWeight = 1;
  static const int humidityWeight = 1;

  /// Calculates flood risk level based on current weather data and other factors
  /// 
  /// [latitude] - Location latitude
  /// [longitude] - Location longitude
  /// [elevation] - Location elevation in meters
  /// [userReports] - Number of validated flood reports from the same region
  /// [scpRiskLevel] - SCP risk level ("Above Normal", "Normal", or "Below Normal")
  /// [floodZoneMatch] - Whether the location is in a known flood zone
  /// 
  /// Returns a risk level as a String: "Low", "Medium", or "High"
  Future<String> calculateFloodRisk({
    required double latitude,
    required double longitude,
    required double elevation,
    required int userReports,
    required String scpRiskLevel,
    required bool floodZoneMatch,
  }) async {
    try {
      final riskData = await getDetailedFloodRisk(
        latitude: latitude,
        longitude: longitude,
        elevation: elevation,
        userReports: userReports,
        scpRiskLevel: scpRiskLevel,
        floodZoneMatch: floodZoneMatch,
      );
      
      return riskData['riskLevel'] as String;
    } catch (e) {
      log('Error calculating flood risk: $e', error: e);
      return 'Medium'; // Default to medium on error
    }
  }

  /// Gets detailed flood risk information including weather data
  /// 
  /// Returns a map containing:
  /// - riskLevel: The calculated risk level ("Low", "Medium", or "High")
  /// - weatherData: The current weather data
  /// - score: The calculated risk score (0-7)
  /// - factors: A list of contributing risk factors
  Future<Map<String, dynamic>> getDetailedFloodRisk({
    required double latitude,
    required double longitude,
    required double elevation,
    required int userReports,
    required String scpRiskLevel,
    required bool floodZoneMatch,
  }) async {
    try {
      final weatherData = await _weatherService.getWeatherForLocation(latitude, longitude);
      
      // If there are more than 2 user reports, return High risk immediately
      if (userReports > 2) {
        return _buildRiskResponse(
          riskLevel: 'High',
          score: 7, // Override score to ensure High risk
          weatherData: weatherData,
          factors: [
            'High number of user reports (>2)',
            'Current rainfall: ${weatherData.rainfall}mm',
            'Rain intensity: ${weatherData.rainIntensity}mm/h',
            'Elevation: ${elevation}m',
            'SCP Risk Level: $scpRiskLevel',
            'Flood Zone Match: ${floodZoneMatch ? "Yes" : "No"}',
          ],
        );
      }

      int score = 0;
      final factors = <String>[];

      // 1. Rainfall scoring (40mm threshold) - 2 points
      if (weatherData.rainfall > 40) {
        score += rainfallWeight;
        factors.add('Heavy rainfall (>40mm): +$rainfallWeight');
      }

      // 2. Elevation scoring (30m threshold) - 2 points
      if (elevation < 30) {
        score += elevationWeight;
        factors.add('Low elevation (<30m): +$elevationWeight');
      }

      // 3. SCP risk level scoring - 0-2 points
      final normalizedScpLevel = scpRiskLevel.trim().toLowerCase();
      switch (normalizedScpLevel) {
        case 'above normal':
          score += scpAboveNormalWeight;
          factors.add('Above Normal SCP risk level: +$scpAboveNormalWeight');
          break;
        case 'normal':
          score += scpNormalWeight;
          factors.add('Normal SCP risk level: +$scpNormalWeight');
          break;
        case 'below normal':
        default:
          factors.add('Below Normal SCP risk level: +0');
          break;
      }

      // 4. Rain intensity scoring (10mm/h threshold) - 1 point
      if (weatherData.rainIntensity > 10) {
        score += rainIntensityWeight;
        factors.add('High rain intensity (>10mm/h): +$rainIntensityWeight');
      }

      // 5. Humidity scoring (80% threshold) - 1 point
      if (weatherData.humidity > 0.8) {
        score += humidityWeight;
        factors.add('High humidity (>80%): +$humidityWeight');
      }

      // Determine final risk level based on total score (0-7 scale)
      final String riskLevel;
      if (score >= highRiskThreshold) {
        riskLevel = 'High';
      } else if (score >= mediumRiskThreshold) {
        riskLevel = 'Medium';
      } else {
        riskLevel = 'Low';
      }

      return _buildRiskResponse(
        riskLevel: riskLevel,
        score: score,
        weatherData: weatherData,
        factors: factors,
      );
    } catch (e) {
      log('Error in getDetailedFloodRisk: $e', error: e);
      return _buildErrorResponse(e);
    }
  }
  
  /// Builds a standardized risk response map
  Map<String, dynamic> _buildRiskResponse({
    required String riskLevel,
    required int score,
    required WeatherData weatherData,
    required List<String> factors,
  }) {
    return {
      'riskLevel': riskLevel,
      'score': score,
      'weatherData': weatherData,
      'factors': factors,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Builds an error response
  Map<String, dynamic> _buildErrorResponse(dynamic error) {
    log('Error in flood risk calculation', error: error);
    return _buildRiskResponse(
      riskLevel: 'Medium',
      score: 3, // Middle of the road score on error
      weatherData: WeatherData.defaultData(),
      factors: [
        'Error calculating risk: ${error.toString()}',
        'Using default medium risk level',
      ],
    );
  }
}