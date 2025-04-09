class GeofenceRegion {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String severity;
  final String description;

  GeofenceRegion({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.severity,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'severity': severity,
      'description': description,
    };
  }

  factory GeofenceRegion.fromJson(Map<String, dynamic> json) {
    return GeofenceRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      radius: json['radius'] as double,
      severity: json['severity'] as String,
      description: json['description'] as String,
    );
  }
} 