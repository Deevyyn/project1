import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cursortest/models/weather_data.dart';
import 'package:cursortest/models/flood_report.dart';
import 'package:cursortest/services/weather_service.dart';

class RiskAssessmentService {
  static final RiskAssessmentService _instance = RiskAssessmentService._internal();
  factory RiskAssessmentService() => _instance;
  RiskAssessmentService._internal();

  final WeatherService _weatherService = WeatherService();
  
  // Risk factor weights (sum should be 1.0)
  static const double _rainfallWeight = 0.35;
  static const double _historicalWeight = 0.25;
  static const double _terrainWeight = 0.20;
  static const double _userReportsWeight = 0.15;
  static const double _scpWeight = 0.05;
  
  // Cold start weights (when historical data is limited)
  static const double _coldStartRainfallWeight = 0.45;
  static const double _coldStartTerrainWeight = 0.30;
  static const double _coldStartScpWeight = 0.25;
  
  // Risk thresholds
  static const double _criticalRiskThreshold = 0.8;
  static const double _highRiskThreshold = 0.6;
  static const double _mediumRiskThreshold = 0.4;
  static const double _lowRiskThreshold = 0.2;
  
  // Calculate overall flood risk based on all available data
  Future<double> calculateFloodRisk(double latitude, double longitude) async {
    try {
      // Get current weather data
      final weatherData = await _weatherService.getCurrentWeather();
      
      // Calculate individual risk factors
      final rainfallRisk = _calculateRainfallRisk(weatherData);
      final historicalRisk = await _calculateHistoricalRisk(latitude, longitude);
      final terrainRisk = await _calculateTerrainRisk(latitude, longitude);
      final userReportsRisk = await _calculateUserReportsRisk(latitude, longitude);
      final scpRisk = await _calculateScpRisk(latitude, longitude);
      
      // Check if we have enough historical data
      final hasHistoricalData = await _hasEnoughHistoricalData(latitude, longitude);
      
      // Calculate weighted risk based on data availability
      double overallRisk;
      
      if (hasHistoricalData) {
        // Normal risk calculation with all factors
        overallRisk = (rainfallRisk * _rainfallWeight) +
                     (historicalRisk * _historicalWeight) +
                     (terrainRisk * _terrainWeight) +
                     (userReportsRisk * _userReportsWeight) +
                     (scpRisk * _scpWeight);
      } else {
        // Cold start risk calculation with limited factors
        overallRisk = (rainfallRisk * _coldStartRainfallWeight) +
                     (terrainRisk * _coldStartTerrainWeight) +
                     (scpRisk * _coldStartScpWeight);
        
        // Log that we're using cold start logic
        debugPrint('Using cold start risk assessment for region: $latitude, $longitude');
      }
      
      // Cache the risk assessment result
      await _cacheRiskAssessment(latitude, longitude, overallRisk);
      
      return overallRisk.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Error calculating flood risk: $e');
      // Return a default risk value in case of error
      return 0.5;
    }
  }
  
  // Calculate risk based on current rainfall data
  double _calculateRainfallRisk(WeatherData weatherData) {
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
    if (weatherData.humidity > 80) {
      risk += 0.1;
    }
    
    // Low temperature can indicate frozen ground, which increases runoff
    if (weatherData.temperature < 5) {
      risk += 0.1;
    }
    
    // Cap the risk at 1.0 (100%)
    return risk.clamp(0.0, 1.0);
  }
  
  // Calculate risk based on historical flood data
  Future<double> _calculateHistoricalRisk(double latitude, double longitude) async {
    try {
      // Get historical flood reports for this region
      final historicalReports = await _getHistoricalFloodReports(latitude, longitude);
      
      if (historicalReports.isEmpty) {
        return 0.0; // No historical data
      }
      
      // Calculate risk based on frequency and severity of past floods
      double risk = 0.0;
      
      // Count reports by severity
      int lowSeverityCount = 0;
      int mediumSeverityCount = 0;
      int highSeverityCount = 0;
      
      for (var report in historicalReports) {
        switch (report.severity) {
          case FloodSeverity.low:
            lowSeverityCount++;
            break;
          case FloodSeverity.medium:
            mediumSeverityCount++;
            break;
          case FloodSeverity.high:
            highSeverityCount++;
            break;
        }
      }
      
      // Calculate risk based on severity counts
      final totalReports = historicalReports.length;
      
      if (totalReports > 0) {
        // Weight high severity reports more heavily
        risk += (lowSeverityCount / totalReports) * 0.2;
        risk += (mediumSeverityCount / totalReports) * 0.5;
        risk += (highSeverityCount / totalReports) * 0.8;
        
        // Factor in recency of reports (more recent = higher risk)
        final mostRecentReport = historicalReports.reduce((a, b) => 
          a.timestamp.isAfter(b.timestamp) ? a : b);
        
        final daysSinceLastReport = DateTime.now().difference(mostRecentReport.timestamp).inDays;
        
        // If the last report was within the last month, increase risk
        if (daysSinceLastReport < 30) {
          risk += 0.1;
        }
      }
      
      return risk.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Error calculating historical risk: $e');
      return 0.0;
    }
  }
  
  // Calculate risk based on terrain information
  Future<double> _calculateTerrainRisk(double latitude, double longitude) async {
    try {
      // In a real app, this would fetch terrain data from a GIS service
      // For now, we'll use a simplified approach with elevation data
      
      // Get elevation data (this would be from a real API in production)
      final elevation = await _getElevationData(latitude, longitude);
      
      // Lower elevation = higher risk
      double risk = 0.0;
      
      if (elevation < 10) {
        risk = 0.9; // Very low elevation (high risk)
      } else if (elevation < 50) {
        risk = 0.7; // Low elevation
      } else if (elevation < 100) {
        risk = 0.5; // Medium elevation
      } else if (elevation < 200) {
        risk = 0.3; // Higher elevation
      } else {
        risk = 0.1; // High elevation (low risk)
      }
      
      // Check if area is near a river or water body
      final isNearWater = await _isNearWaterBody(latitude, longitude);
      if (isNearWater) {
        risk += 0.2; // Increase risk if near water
      }
      
      return risk.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Error calculating terrain risk: $e');
      return 0.5; // Default to medium risk
    }
  }
  
  // Calculate risk based on user reports
  Future<double> _calculateUserReportsRisk(double latitude, double longitude) async {
    try {
      // Get recent user reports for this region
      final recentReports = await _getRecentUserReports(latitude, longitude);
      
      if (recentReports.isEmpty) {
        return 0.0; // No recent reports
      }
      
      // Calculate risk based on number and severity of recent reports
      double risk = 0.0;
      
      // Count reports by severity
      int lowSeverityCount = 0;
      int mediumSeverityCount = 0;
      int highSeverityCount = 0;
      
      for (var report in recentReports) {
        switch (report.severity) {
          case FloodSeverity.low:
            lowSeverityCount++;
            break;
          case FloodSeverity.medium:
            mediumSeverityCount++;
            break;
          case FloodSeverity.high:
            highSeverityCount++;
            break;
        }
      }
      
      // Calculate risk based on severity counts
      final totalReports = recentReports.length;
      
      if (totalReports > 0) {
        // Weight high severity reports more heavily
        risk += (lowSeverityCount / totalReports) * 0.3;
        risk += (mediumSeverityCount / totalReports) * 0.6;
        risk += (highSeverityCount / totalReports) * 0.9;
        
        // Factor in report density (more reports in a small area = higher risk)
        final reportDensity = _calculateReportDensity(recentReports);
        risk += reportDensity * 0.2;
      }
      
      return risk.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Error calculating user reports risk: $e');
      return 0.0;
    }
  }
  
  // Calculate risk based on Seasonal Climate Prediction (SCP) data
  Future<double> _calculateScpRisk(double latitude, double longitude) async {
    try {
      // In a real app, this would fetch SCP data from NiMet
      // For now, we'll use a simplified approach based on the current month
      
      // Get the current month (1-12)
      final currentMonth = DateTime.now().month;
      
      // Define flood-prone months (example: rainy season months)
      final floodProneMonths = [4, 5, 6, 7, 8, 9, 10]; // Example months
      
      // Check if current month is in flood-prone period
      final isFloodProneMonth = floodProneMonths.contains(currentMonth);
      
      // Get forecasted rainfall anomaly (this would be from NiMet in production)
      final rainfallAnomaly = await _getRainfallAnomaly(latitude, longitude);
      
      double risk = 0.0;
      
      // Base risk on flood-prone period
      if (isFloodProneMonth) {
        risk = 0.4; // Base risk during flood-prone months
      } else {
        risk = 0.1; // Lower base risk outside flood-prone months
      }
      
      // Adjust risk based on rainfall anomaly
      if (rainfallAnomaly > 0.5) {
        risk += 0.3; // Significant above-normal rainfall expected
      } else if (rainfallAnomaly > 0.2) {
        risk += 0.2; // Above-normal rainfall expected
      } else if (rainfallAnomaly < -0.2) {
        risk -= 0.1; // Below-normal rainfall expected
      }
      
      return risk.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Error calculating SCP risk: $e');
      return 0.2; // Default to low risk
    }
  }
  
  // Check if we have enough historical data for a region
  Future<bool> _hasEnoughHistoricalData(double latitude, double longitude) async {
    try {
      // Get historical flood reports for this region
      final historicalReports = await _getHistoricalFloodReports(latitude, longitude);
      
      // Consider we have enough data if there are at least 3 reports
      return historicalReports.length >= 3;
    } catch (e) {
      debugPrint('Error checking historical data: $e');
      return false;
    }
  }
  
  // Get risk level description
  String getRiskLevelDescription(double risk) {
    if (risk >= _criticalRiskThreshold) {
      return 'Critical';
    } else if (risk >= _highRiskThreshold) {
      return 'High';
    } else if (risk >= _mediumRiskThreshold) {
      return 'Medium';
    } else if (risk >= _lowRiskThreshold) {
      return 'Low';
    } else {
      return 'Minimal';
    }
  }
  
  // Get risk level color
  Color getRiskLevelColor(double risk) {
    if (risk >= _criticalRiskThreshold) {
      return const Color(0xFFF44336); // Red
    } else if (risk >= _highRiskThreshold) {
      return const Color(0xFFFF9800); // Orange
    } else if (risk >= _mediumRiskThreshold) {
      return const Color(0xFFFFC107); // Yellow
    } else if (risk >= _lowRiskThreshold) {
      return const Color(0xFF4CAF50); // Green
    } else {
      return const Color(0xFF2196F3); // Blue
    }
  }
  
  // Get risk level icon
  IconData getRiskLevelIcon(double risk) {
    if (risk >= _criticalRiskThreshold) {
      return Icons.warning_rounded;
    } else if (risk >= _highRiskThreshold) {
      return Icons.error_outline;
    } else if (risk >= _mediumRiskThreshold) {
      return Icons.info_outline;
    } else if (risk >= _lowRiskThreshold) {
      return Icons.check_circle_outline;
    } else {
      return Icons.check_circle_outline;
    }
  }
  
  // Get risk level recommendations
  List<String> getRiskLevelRecommendations(double risk) {
    if (risk >= _criticalRiskThreshold) {
      return [
        'Immediate evacuation may be necessary',
        'Avoid all flood-prone areas',
        'Monitor emergency broadcasts',
        'Prepare emergency kit',
        'Contact emergency services if trapped'
      ];
    } else if (risk >= _highRiskThreshold) {
      return [
        'Be prepared for possible flooding',
        'Avoid low-lying areas',
        'Monitor weather updates',
        'Prepare emergency supplies',
        'Have an evacuation plan ready'
      ];
    } else if (risk >= _mediumRiskThreshold) {
      return [
        'Stay alert for changing conditions',
        'Avoid flood-prone areas',
        'Monitor local weather',
        'Keep emergency supplies handy',
        'Know your evacuation routes'
      ];
    } else if (risk >= _lowRiskThreshold) {
      return [
        'Monitor weather conditions',
        'Be aware of flood risks',
        'Know your local emergency contacts',
        'Have a basic emergency plan'
      ];
    } else {
      return [
        'Stay informed about weather changes',
        'Know your local emergency contacts',
        'Have a basic emergency plan'
      ];
    }
  }
  
  // Helper methods for data retrieval (would be implemented with real APIs in production)
  
  Future<List<FloodReport>> _getHistoricalFloodReports(double latitude, double longitude) async {
    // In a real app, this would fetch from a database or API
    // For now, we'll return mock data
    return [];
  }
  
  Future<List<FloodReport>> _getRecentUserReports(double latitude, double longitude) async {
    // In a real app, this would fetch from a database or API
    // For now, we'll return mock data
    return [];
  }
  
  Future<double> _getElevationData(double latitude, double longitude) async {
    // In a real app, this would fetch from a GIS service
    // For now, we'll return a mock value
    return 50.0; // 50 meters above sea level
  }
  
  Future<bool> _isNearWaterBody(double latitude, double longitude) async {
    // In a real app, this would check against a map of water bodies
    // For now, we'll return a mock value
    return true;
  }
  
  Future<double> _getRainfallAnomaly(double latitude, double longitude) async {
    // In a real app, this would fetch from NiMet
    // For now, we'll return a mock value
    return 0.3; // 30% above normal
  }
  
  double _calculateReportDensity(List<FloodReport> reports) {
    if (reports.length < 2) return 0.0;
    
    // Calculate the average distance between reports
    double totalDistance = 0.0;
    int count = 0;
    
    for (int i = 0; i < reports.length; i++) {
      for (int j = i + 1; j < reports.length; j++) {
        totalDistance += _calculateDistance(
          reports[i].latitude, reports[i].longitude,
          reports[j].latitude, reports[j].longitude
        );
        count++;
      }
    }
    
    if (count == 0) return 0.0;
    
    final averageDistance = totalDistance / count;
    
    // Convert to a 0-1 scale (closer reports = higher density = higher risk)
    // Assuming 5km is the threshold for "very dense" reports
    return (1.0 - (averageDistance / 5000)).clamp(0.0, 1.0);
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula to calculate distance between two points on Earth
    const double earthRadius = 6371000; // meters
    
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;
    
    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
              cos(phi1) * cos(phi2) *
              sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  // Cache risk assessment results
  Future<void> _cacheRiskAssessment(double latitude, double longitude, double risk) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'risk_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';
      
      final data = {
        'risk': risk,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(key, data.toString());
    } catch (e) {
      debugPrint('Error caching risk assessment: $e');
    }
  }
} 