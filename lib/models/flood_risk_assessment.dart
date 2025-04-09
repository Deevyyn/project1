import 'package:cursortest/models/terrain_data.dart';
import 'package:cursortest/models/weather_data.dart';

class FloodRiskAssessment {
  final TerrainData terrainData;
  final WeatherData weatherData;
  final DateTime assessmentTime;
  final String locationId;
  final String locationName;
  final double? historicalFloodRisk; // 0.0 to 1.0
  final Map<String, dynamic>? additionalData;

  FloodRiskAssessment({
    required this.terrainData,
    required this.weatherData,
    required this.assessmentTime,
    required this.locationId,
    required this.locationName,
    this.historicalFloodRisk,
    this.additionalData,
  });

  // Create FloodRiskAssessment from JSON
  factory FloodRiskAssessment.fromJson(Map<String, dynamic> json) {
    return FloodRiskAssessment(
      terrainData: TerrainData.fromJson(json['terrainData']),
      weatherData: WeatherData.fromJson(json['weatherData']),
      assessmentTime: DateTime.parse(json['assessmentTime']),
      locationId: json['locationId'],
      locationName: json['locationName'],
      historicalFloodRisk: json['historicalFloodRisk'],
      additionalData: json['additionalData'],
    );
  }

  // Convert FloodRiskAssessment to JSON
  Map<String, dynamic> toJson() {
    return {
      'terrainData': terrainData.toJson(),
      'weatherData': weatherData.toJson(),
      'assessmentTime': assessmentTime.toIso8601String(),
      'locationId': locationId,
      'locationName': locationName,
      'historicalFloodRisk': historicalFloodRisk,
      'additionalData': additionalData,
    };
  }

  // Calculate overall flood risk (0.0 to 1.0)
  double calculateOverallRisk() {
    // Get individual risk factors
    double terrainRisk = terrainData.calculateFloodRiskFactor();
    double weatherRisk = weatherData.calculateFloodRiskFactor();
    
    // Use historical risk if available, otherwise use a default value
    double historicalRisk = historicalFloodRisk ?? 0.5;
    
    // Weighted average of all factors
    // Terrain is most important (40%), followed by weather (35%), then historical data (25%)
    return (
      terrainRisk * 0.4 +
      weatherRisk * 0.35 +
      historicalRisk * 0.25
    ).clamp(0.0, 1.0);
  }

  // Get risk level as text
  String getRiskLevel() {
    double risk = calculateOverallRisk();
    
    if (risk >= 0.8) {
      return 'Extreme';
    } else if (risk >= 0.6) {
      return 'High';
    } else if (risk >= 0.4) {
      return 'Moderate';
    } else if (risk >= 0.2) {
      return 'Low';
    } else {
      return 'Minimal';
    }
  }

  // Get risk level color
  int getRiskLevelColor() {
    double risk = calculateOverallRisk();
    
    if (risk >= 0.8) {
      return 0xFFD32F2F; // Red
    } else if (risk >= 0.6) {
      return 0xFFF57C00; // Orange
    } else if (risk >= 0.4) {
      return 0xFFFFEB3B; // Yellow
    } else if (risk >= 0.2) {
      return 0xFF4CAF50; // Green
    } else {
      return 0xFF2196F3; // Blue
    }
  }

  // Get risk level icon
  String getRiskLevelIcon() {
    double risk = calculateOverallRisk();
    
    if (risk >= 0.8) {
      return 'warning';
    } else if (risk >= 0.6) {
      return 'error';
    } else if (risk >= 0.4) {
      return 'info';
    } else if (risk >= 0.2) {
      return 'check_circle';
    } else {
      return 'check';
    }
  }

  // Get safety recommendations based on risk level
  List<String> getSafetyRecommendations() {
    double risk = calculateOverallRisk();
    List<String> recommendations = [];
    
    if (risk >= 0.8) {
      recommendations.addAll([
        'Evacuate immediately if in a flood-prone area',
        'Move to higher ground',
        'Avoid walking or driving through flood waters',
        'Stay tuned to emergency broadcasts',
        'Prepare emergency kit with essential supplies',
      ]);
    } else if (risk >= 0.6) {
      recommendations.addAll([
        'Be prepared to evacuate if conditions worsen',
        'Monitor water levels in your area',
        'Secure important documents and valuables',
        'Have an emergency plan ready',
        'Stay informed about weather updates',
      ]);
    } else if (risk >= 0.4) {
      recommendations.addAll([
        'Monitor local weather conditions',
        'Check your property for potential flood entry points',
        'Ensure gutters and drains are clear',
        'Keep emergency supplies handy',
        'Know your evacuation route',
      ]);
    } else if (risk >= 0.2) {
      recommendations.addAll([
        'Stay alert to changing conditions',
        'Keep emergency contact numbers handy',
        'Review your emergency plan',
        'Check your insurance coverage',
      ]);
    } else {
      recommendations.addAll([
        'Monitor weather forecasts',
        'Keep emergency supplies stocked',
        'Know your local emergency procedures',
      ]);
    }
    
    return recommendations;
  }

  // Check if current conditions indicate immediate action is needed
  bool requiresImmediateAction() {
    return calculateOverallRisk() >= 0.7 || 
           weatherData.isHighFloodRisk() || 
           terrainData.isFloodplain;
  }

  // Create a copy of this assessment with updated fields
  FloodRiskAssessment copyWith({
    TerrainData? terrainData,
    WeatherData? weatherData,
    DateTime? assessmentTime,
    String? locationId,
    String? locationName,
    double? historicalFloodRisk,
    Map<String, dynamic>? additionalData,
  }) {
    return FloodRiskAssessment(
      terrainData: terrainData ?? this.terrainData,
      weatherData: weatherData ?? this.weatherData,
      assessmentTime: assessmentTime ?? this.assessmentTime,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      historicalFloodRisk: historicalFloodRisk ?? this.historicalFloodRisk,
      additionalData: additionalData ?? this.additionalData,
    );
  }
} 