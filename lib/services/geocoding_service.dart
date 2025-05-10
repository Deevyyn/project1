import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _apiKey = "e5960e08f75e4c28a0226eac47c3941c";
  static const String _endpoint = "https://api.opencagedata.com/geocode/v1/json";

  /// Returns a map with 'lat' and 'lng' if successful, or null if not found/error.
  static Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'q': address,
      'key': _apiKey,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          final geometry = results[0]['geometry'];
          final lat = geometry['lat'] as double?;
          final lng = geometry['lng'] as double?;
          if (lat != null && lng != null) {
            return {'lat': lat, 'lng': lng};
          }
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return null;
  }
} 