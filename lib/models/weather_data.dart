class WeatherData {
  final double rainfall; // in mm
  final double rainIntensity; // in mm/hour
  final double rainDuration; // in hours
  final double temperature; // in Celsius
  final double humidity; // 0.0 to 1.0
  final double windSpeed; // in m/s
  final String weatherCondition; // e.g., 'rain', 'storm', 'clear'
  final String description;
  final double feelsLike;
  final double visibility;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;

  WeatherData({
    required this.rainfall,
    required this.rainIntensity,
    required this.rainDuration,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCondition,
    required this.description,
    required this.feelsLike,
    required this.visibility,
    required this.timestamp,
    this.additionalData,
  });

  // For backward compatibility
  DateTime get dateTime => timestamp;

  // Create WeatherData from JSON
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      rainfall: json['rainfall']?.toDouble() ?? 0.0,
      rainIntensity: json['rainIntensity']?.toDouble() ?? 0.0,
      rainDuration: json['rainDuration']?.toDouble() ?? 0.0,
      temperature: json['temperature']?.toDouble() ?? 0.0,
      humidity: json['humidity']?.toDouble() ?? 0.0,
      windSpeed: json['windSpeed']?.toDouble() ?? 0.0,
      weatherCondition: json['weatherCondition'] ?? 'unknown',
      description: json['description'] ?? 'N/A',
      feelsLike: json['feelsLike']?.toDouble() ?? 0.0,
      visibility: json['visibility']?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      additionalData: json['additionalData'],
    );
  }

  // Convert WeatherData to JSON
  Map<String, dynamic> toJson() {
    return {
      'rainfall': rainfall,
      'rainIntensity': rainIntensity,
      'rainDuration': rainDuration,
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'weatherCondition': weatherCondition,
      'description': description,
      'feelsLike': feelsLike,
      'visibility': visibility,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }

  // Create default WeatherData
  factory WeatherData.defaultData() {
    return WeatherData(
      rainfall: 0.0,
      rainIntensity: 0.0,
      rainDuration: 0.0,
      temperature: 20.0,
      humidity: 0.5,
      windSpeed: 0.0,
      weatherCondition: 'clear',
      description: 'No data available',
      feelsLike: 20.0,
      visibility: 10000.0,
      timestamp: DateTime.now(),
      additionalData: null,
    );
  }

  // Calculate flood risk factor based on weather conditions (0.0 to 1.0)
  double calculateFloodRiskFactor() {
    // Initialize risk factors
    double rainfallRisk = _calculateRainfallRisk();
    double intensityRisk = _calculateIntensityRisk();
    double conditionRisk = _calculateWeatherConditionRisk();
    double humidityRisk = _calculateHumidityRisk();
    
    // Weighted average of all factors
    // Rainfall intensity is most important (40%), followed by total rainfall (30%), 
    // then weather condition (20%), and humidity (10%)
    return (
      intensityRisk * 0.4 +
      rainfallRisk * 0.3 +
      conditionRisk * 0.2 +
      humidityRisk * 0.1
    ).clamp(0.0, 1.0);
  }

  // Add weather risk calculation method (alias for calculateFloodRiskFactor)
  double calculateWeatherRiskFactor() {
    return calculateFloodRiskFactor();
  }

  // Calculate risk based on total rainfall
  double _calculateRainfallRisk() {
    // Normalize rainfall to a 0-1 scale (assuming rainfall between 0-100mm)
    // Higher rainfall means higher risk
    return (rainfall / 100.0).clamp(0.0, 1.0);
  }

  // Calculate risk based on rainfall intensity
  double _calculateIntensityRisk() {
    // Normalize intensity to a 0-1 scale (assuming intensity between 0-50mm/hour)
    // Higher intensity means higher risk
    return (rainIntensity / 50.0).clamp(0.0, 1.0);
  }

  // Calculate risk based on weather condition
  double _calculateWeatherConditionRisk() {
    switch (weatherCondition.toLowerCase()) {
      case 'storm':
      case 'thunderstorm':
        return 1.0; // Highest risk
      case 'heavy rain':
        return 0.9;
      case 'rain':
        return 0.7;
      case 'light rain':
        return 0.5;
      case 'drizzle':
        return 0.3;
      case 'clear':
      case 'sunny':
        return 0.1; // Lowest risk
      default:
        return 0.5; // Default moderate risk
    }
  }

  // Calculate risk based on humidity
  double _calculateHumidityRisk() {
    // Higher humidity means higher risk (soil saturation)
    return humidity;
  }

  // Check if the weather conditions indicate high flood risk
  bool isHighFloodRisk() {
    return calculateFloodRiskFactor() >= 0.7 || 
           rainIntensity >= 30.0 || // Heavy rainfall
           (rainfall >= 50.0 && weatherCondition.toLowerCase().contains('rain')); // Significant rainfall
  }

  // Get weather condition description
  String getWeatherConditionDescription() {
    switch (weatherCondition.toLowerCase()) {
      case 'storm':
      case 'thunderstorm':
        return 'Severe storm conditions';
      case 'heavy rain':
        return 'Heavy rainfall';
      case 'rain':
        return 'Moderate rainfall';
      case 'light rain':
        return 'Light rainfall';
      case 'drizzle':
        return 'Light drizzle';
      case 'clear':
      case 'sunny':
        return 'Clear weather';
      default:
        return 'Unknown weather condition';
    }
  }

  // Get weather icon URL based on condition
  String getWeatherIconUrl() {
    final iconCode = additionalData?['icon'] as String? ?? '01d';
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  // Create a copy of this weather data with updated fields
  WeatherData copyWith({
    double? rainfall,
    double? rainIntensity,
    double? rainDuration,
    double? temperature,
    double? humidity,
    double? windSpeed,
    String? weatherCondition,
    String? description,
    double? feelsLike,
    double? visibility,
    DateTime? timestamp,
    Map<String, dynamic>? additionalData,
  }) {
    return WeatherData(
      rainfall: rainfall ?? this.rainfall,
      rainIntensity: rainIntensity ?? this.rainIntensity,
      rainDuration: rainDuration ?? this.rainDuration,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      description: description ?? this.description,
      feelsLike: feelsLike ?? this.feelsLike,
      visibility: visibility ?? this.visibility,
      timestamp: timestamp ?? this.timestamp,
      additionalData: additionalData ?? this.additionalData,
    );
  }
} 