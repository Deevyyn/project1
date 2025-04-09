class FloodAlert {
  final String id;
  final double latitude;
  final double longitude;
  final String description;
  final String imageUrl;
  final DateTime timestamp;
  final String reportedBy;
  final String severity;

  FloodAlert({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.imageUrl,
    required this.timestamp,
    required this.reportedBy,
    required this.severity,
  });

  factory FloodAlert.fromJson(Map<String, dynamic> json) {
    return FloodAlert(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      timestamp: DateTime.parse(json['timestamp']),
      reportedBy: json['reportedBy'],
      severity: json['severity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'reportedBy': reportedBy,
      'severity': severity,
    };
  }
} 