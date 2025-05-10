import 'dart:convert';
import 'package:http/http.dart' as http;

class ElevationService {
  static Future<double?> fetchElevation(double latitude, double longitude) async {
    final url = 'https://api.open-elevation.com/api/v1/lookup?locations=$latitude,$longitude';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results']?[0]?['elevation'] as num?)?.toDouble();
      }
    } catch (_) {}
    return null;
  }
} 