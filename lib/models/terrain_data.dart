class TerrainData {
  final double elevation; // in meters
  final double slope; // in degrees
  final bool isFloodplain;
  final double distanceToWaterBody; // in meters
  final String soilType; // e.g., 'clay', 'sandy', 'loamy'
  final double soilMoisture; // 0.0 to 1.0
  final double vegetationCover; // 0.0 to 1.0
  final Map<String, dynamic>? additionalData;

  TerrainData({
    required this.elevation,
    required this.slope,
    required this.isFloodplain,
    required this.distanceToWaterBody,
    required this.soilType,
    required this.soilMoisture,
    required this.vegetationCover,
    this.additionalData,
  });

  // Create TerrainData from JSON
  factory TerrainData.fromJson(Map<String, dynamic> json) {
    return TerrainData(
      elevation: json['elevation'].toDouble(),
      slope: json['slope'].toDouble(),
      isFloodplain: json['isFloodplain'],
      distanceToWaterBody: json['distanceToWaterBody'].toDouble(),
      soilType: json['soilType'],
      soilMoisture: json['soilMoisture'].toDouble(),
      vegetationCover: json['vegetationCover'].toDouble(),
      additionalData: json['additionalData'],
    );
  }

  // Convert TerrainData to JSON
  Map<String, dynamic> toJson() {
    return {
      'elevation': elevation,
      'slope': slope,
      'isFloodplain': isFloodplain,
      'distanceToWaterBody': distanceToWaterBody,
      'soilType': soilType,
      'soilMoisture': soilMoisture,
      'vegetationCover': vegetationCover,
      'additionalData': additionalData,
    };
  }

  // Calculate flood risk factor based on terrain characteristics (0.0 to 1.0)
  double calculateFloodRiskFactor() {
    // Initialize risk factors
    double elevationRisk = _calculateElevationRisk();
    double slopeRisk = _calculateSlopeRisk();
    double floodplainRisk = isFloodplain ? 1.0 : 0.0;
    double waterBodyRisk = _calculateWaterBodyRisk();
    double soilRisk = _calculateSoilRisk();
    double vegetationRisk = _calculateVegetationRisk();
    
    // Weighted average of all factors
    // Floodplain is most important (30%), followed by elevation (20%), 
    // then water body proximity (15%), soil type (15%), slope (10%), and vegetation (10%)
    return (
      floodplainRisk * 0.3 +
      elevationRisk * 0.2 +
      waterBodyRisk * 0.15 +
      soilRisk * 0.15 +
      slopeRisk * 0.1 +
      vegetationRisk * 0.1
    ).clamp(0.0, 1.0);
  }

  // Calculate risk based on elevation (lower elevation = higher risk)
  double _calculateElevationRisk() {
    // Normalize elevation to a 0-1 scale (assuming elevations between 0-1000m)
    // Lower elevation means higher risk
    return (1.0 - (elevation / 1000.0)).clamp(0.0, 1.0);
  }

  // Calculate risk based on slope (lower slope = higher risk)
  double _calculateSlopeRisk() {
    // Normalize slope to a 0-1 scale (assuming slopes between 0-45 degrees)
    // Lower slope means higher risk
    return (1.0 - (slope / 45.0)).clamp(0.0, 1.0);
  }

  // Calculate risk based on proximity to water bodies
  double _calculateWaterBodyRisk() {
    // Normalize distance to a 0-1 scale (assuming distances between 0-1000m)
    // Closer to water body means higher risk
    return (1.0 - (distanceToWaterBody / 1000.0)).clamp(0.0, 1.0);
  }

  // Calculate risk based on soil type and moisture
  double _calculateSoilRisk() {
    // Base risk from soil type
    double soilTypeRisk = _getSoilTypeRiskFactor();
    
    // Combine with soil moisture (higher moisture = higher risk)
    return ((soilTypeRisk + soilMoisture) / 2.0).clamp(0.0, 1.0);
  }

  // Get risk factor for different soil types
  double _getSoilTypeRiskFactor() {
    switch (soilType.toLowerCase()) {
      case 'clay':
        return 0.9; // Clay soils have poor drainage
      case 'sandy':
        return 0.3; // Sandy soils have good drainage
      case 'loamy':
        return 0.6; // Loamy soils have moderate drainage
      case 'silt':
        return 0.8; // Silty soils have poor drainage
      default:
        return 0.5; // Default moderate risk
    }
  }

  // Calculate risk based on vegetation cover (lower cover = higher risk)
  double _calculateVegetationRisk() {
    // Vegetation helps reduce flood risk by absorbing water and reducing runoff
    return (1.0 - vegetationCover).clamp(0.0, 1.0);
  }

  // Check if the terrain is at high risk for flooding
  bool isHighFloodRisk() {
    return calculateFloodRiskFactor() >= 0.7 || 
           isFloodplain || 
           (elevation < 10 && distanceToWaterBody < 100);
  }

  // Create a copy of this terrain data with updated fields
  TerrainData copyWith({
    double? elevation,
    double? slope,
    bool? isFloodplain,
    double? distanceToWaterBody,
    String? soilType,
    double? soilMoisture,
    double? vegetationCover,
    Map<String, dynamic>? additionalData,
  }) {
    return TerrainData(
      elevation: elevation ?? this.elevation,
      slope: slope ?? this.slope,
      isFloodplain: isFloodplain ?? this.isFloodplain,
      distanceToWaterBody: distanceToWaterBody ?? this.distanceToWaterBody,
      soilType: soilType ?? this.soilType,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      vegetationCover: vegetationCover ?? this.vegetationCover,
      additionalData: additionalData ?? this.additionalData,
    );
  }
} 