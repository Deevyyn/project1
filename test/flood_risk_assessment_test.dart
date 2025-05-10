import 'package:flutter_test/flutter_test.dart';
import 'package:cursortest/flood_risk_assessment.dart';

void main() {
  group('FloodRiskAssessment', () {
    test('should return High risk when user reports > 2', () {
      final result = FloodRiskAssessment.calculateFloodRisk(
        rainfall: 10.0,
        elevation: 100.0,
        userReports: 3,
        scpRiskLevel: "Normal",
        hasHistoricalFloodData: false,
      );
      expect(result, equals("High"));
    });

    test('should return High risk when score >= 6', () {
      final result = FloodRiskAssessment.calculateFloodRisk(
        rainfall: 45.0,  // +2 points
        elevation: 25.0, // +2 points
        userReports: 0,
        scpRiskLevel: "Above Normal", // +2 points
        hasHistoricalFloodData: true, // +1 point
      );
      expect(result, equals("High"));
    });

    test('should return Medium risk when score between 3 and 5', () {
      final result = FloodRiskAssessment.calculateFloodRisk(
        rainfall: 45.0,  // +2 points
        elevation: 100.0, // 0 points
        userReports: 0,
        scpRiskLevel: "Normal", // +1 point
        hasHistoricalFloodData: false, // 0 points
      );
      expect(result, equals("Medium"));
    });

    test('should return Low risk when score <= 2', () {
      final result = FloodRiskAssessment.calculateFloodRisk(
        rainfall: 20.0,  // 0 points
        elevation: 100.0, // 0 points
        userReports: 0,
        scpRiskLevel: "Normal", // +1 point
        hasHistoricalFloodData: false, // 0 points
      );
      expect(result, equals("Low"));
    });

    test('should handle Below Normal SCP risk level', () {
      final result = FloodRiskAssessment.calculateFloodRisk(
        rainfall: 20.0,  // 0 points
        elevation: 100.0, // 0 points
        userReports: 0,
        scpRiskLevel: "Below Normal", // 0 points
        hasHistoricalFloodData: false, // 0 points
      );
      expect(result, equals("Low"));
    });

    test('should throw ArgumentError for invalid SCP risk level', () {
      expect(
        () => FloodRiskAssessment.calculateFloodRisk(
          rainfall: 20.0,
          elevation: 100.0,
          userReports: 0,
          scpRiskLevel: "Invalid Level",
          hasHistoricalFloodData: false,
        ),
        throwsArgumentError,
      );
    });

    test('should handle edge cases for rainfall threshold', () {
      final result1 = FloodRiskAssessment.calculateFloodRisk(
        rainfall: 40.0,  // 0 points (exactly at threshold)
        elevation: 100.0,
        userReports: 0,
        scpRiskLevel: "Normal",
        hasHistoricalFloodData: false,
      );
      expect(result1, equals("Low"));

      final result2 = FloodRiskAssessment.calculateFloodRisk(
        rainfall: 40.1,  // +2 points (just above threshold)
        elevation: 100.0,
        userReports: 0,
        scpRiskLevel: "Normal",
        hasHistoricalFloodData: false,
      );
      expect(result2, equals("Medium"));
    });

    test('should handle edge cases for elevation threshold', () {
      final result1 = FloodRiskAssessment.calculateFloodRisk(
        rainfall: 20.0,
        elevation: 30.0,  // 0 points (exactly at threshold)
        userReports: 0,
        scpRiskLevel: "Normal",
        hasHistoricalFloodData: false,
      );
      expect(result1, equals("Low"));

      final result2 = FloodRiskAssessment.calculateFloodRisk(
        rainfall: 20.0,
        elevation: 29.9,  // +2 points (just below threshold)
        userReports: 0,
        scpRiskLevel: "Normal",
        hasHistoricalFloodData: false,
      );
      expect(result2, equals("Medium"));
    });
  });
} 