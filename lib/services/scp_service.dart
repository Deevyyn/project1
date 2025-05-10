import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart'; // for debugPrint

class ScpService {
  // Singleton setup
  ScpService._privateConstructor();
  static final ScpService _instance = ScpService._privateConstructor();
  factory ScpService() => _instance;

  // Cache: state name (UPPERCASE) -> data map
  final Map<String, Map<String, dynamic>> _cache = {};

  bool _isLoaded = false;

  // Load data from JSON asset
  Future<void> loadData() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/scp_data.json');
      final List<dynamic> dataList = json.decode(jsonString);
      _cache.clear();
      for (var entry in dataList) {
        if (entry is Map<String, dynamic> && entry['state'] != null) {
          _cache[entry['state'].toString().toUpperCase()] = entry;
        }
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading SCP data: $e');
    }
  }

  // Optionally reload data
  Future<void> reloadData() async {
    _isLoaded = false;
    await loadData();
  }

  // Get SCP data for a state (case-insensitive)
  Map<String, dynamic>? getScpData(String state) {
    if (!_isLoaded) {
      debugPrint('SCP data not loaded yet.');
      return null;
    }
    return _cache[state.toUpperCase()];
  }

  // Check if state is flood-prone
  bool isFloodProne(String state) {
    final data = getScpData(state);
    if (data == null) return false;
    return data['flood_prone'] == true;
  }

  // Get risk level ("High", "Medium", "Low")
  String getRiskLevel(String state) {
    final data = getScpData(state);
    if (data == null) return 'Unknown';
    return data['risk_level'] ?? 'Unknown';
  }

  // Get disaster plan (nullable)
  String? getDisasterPlan(String state) {
    final data = getScpData(state);
    if (data == null) return null;
    return data['disaster_plan'];
  }
} 