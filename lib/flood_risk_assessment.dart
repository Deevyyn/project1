/// A utility class for flood risk assessment calculations.
class FloodRiskAssessment {
  /// Calculates the flood risk level based on various environmental and user-reported factors.
  ///
  /// [rainfall] - Current rainfall amount in millimeters
  /// [elevation] - Elevation of the location in meters
  /// [userReports] - Number of validated flood reports from the same region
  /// [scpRiskLevel] - SCP risk level ("Above Normal", "Normal", or "Below Normal")
  /// [hasHistoricalFloodData] - Whether the region has historical flood data
  ///
  /// Returns a risk level as a String: "Low", "Medium", or "High"
  static String calculateFloodRisk({
    required double rainfall,
    required double elevation,
    required int userReports,
    required String scpRiskLevel,
    required bool hasHistoricalFloodData,
  }) {
    // If there are more than 2 user reports, override to High risk
    if (userReports > 2) {
      return "High";
    }

    int score = 0;

    // Rainfall scoring
    if (rainfall > 40) {
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

    // Determine final risk level based on total score
    if (score >= 6) {
      return "High";
    } else if (score >= 3) {
      return "Medium";
    } else {
      return "Low";
    }
  }
} 