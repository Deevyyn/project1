enum FloodSeverity {
  low,
  medium,
  high
}

class FloodReport {
  final String id;
  final double latitude;
  final double longitude;
  final String description;
  final String? imageUrl;
  final DateTime timestamp;
  final String reportedBy;
  final FloodSeverity severity;
  final bool isVerified;
  final String? locationName;
  final double? waterDepth;
  final String? additionalNotes;
  final bool imageValidated;

  FloodReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.imageUrl,
    required this.timestamp,
    required this.reportedBy,
    required this.severity,
    this.isVerified = false,
    this.locationName,
    this.waterDepth,
    this.additionalNotes,
    this.imageValidated = false,
  });

  // Create a FloodReport from JSON
  factory FloodReport.fromJson(Map<String, dynamic> json) {
    return FloodReport(
      id: json['id'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      reportedBy: json['reportedBy'] ?? '',
      severity: _parseSeverity(json['severity']),
      isVerified: json['isVerified'] ?? false,
      locationName: json['locationName'],
      waterDepth: json['waterDepth'] != null 
          ? (json['waterDepth'] as num).toDouble() 
          : null,
      additionalNotes: json['additionalNotes'],
      imageValidated: json['imageValidated'] ?? false,
    );
  }

  // Convert FloodReport to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'reportedBy': reportedBy,
      'severity': severity.toString().split('.').last,
      'isVerified': isVerified,
      'locationName': locationName,
      'waterDepth': waterDepth,
      'additionalNotes': additionalNotes,
      'imageValidated': imageValidated,
    };
  }

  // Parse severity from string
  static FloodSeverity _parseSeverity(String? severity) {
    if (severity == null) return FloodSeverity.medium;
    
    switch (severity.toLowerCase()) {
      case 'low':
        return FloodSeverity.low;
      case 'high':
        return FloodSeverity.high;
      default:
        return FloodSeverity.medium;
    }
  }

  // Create a copy of this report with updated fields
  FloodReport copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? description,
    String? imageUrl,
    DateTime? timestamp,
    String? reportedBy,
    FloodSeverity? severity,
    bool? isVerified,
    String? locationName,
    double? waterDepth,
    String? additionalNotes,
    bool? imageValidated,
  }) {
    return FloodReport(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      reportedBy: reportedBy ?? this.reportedBy,
      severity: severity ?? this.severity,
      isVerified: isVerified ?? this.isVerified,
      locationName: locationName ?? this.locationName,
      waterDepth: waterDepth ?? this.waterDepth,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      imageValidated: imageValidated ?? this.imageValidated,
    );
  }
} 