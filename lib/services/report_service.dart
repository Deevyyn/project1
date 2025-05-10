import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cursortest/services/elevation_service.dart';

class FloodReport {
  final String id;
  final double latitude;
  final double longitude;
  final String description;
  final String severity;
  final String? imagePath;
  final DateTime timestamp;
  final bool isSubmitted;
  final String? errorMessage;
  final bool imageValidated;
  double? elevation;
  String? riskLevel;

  FloodReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.severity,
    this.imagePath,
    required this.timestamp,
    this.isSubmitted = false,
    this.errorMessage,
    this.imageValidated = false,
    this.elevation,
    this.riskLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'severity': severity,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'isSubmitted': isSubmitted,
      'errorMessage': errorMessage,
      'imageValidated': imageValidated,
      'elevation': elevation,
      'riskLevel': riskLevel,
    };
  }

  factory FloodReport.fromJson(Map<String, dynamic> json) {
    return FloodReport(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      description: json['description'],
      severity: json['severity'],
      imagePath: json['imagePath'],
      timestamp: DateTime.parse(json['timestamp']),
      isSubmitted: json['isSubmitted'] ?? false,
      errorMessage: json['errorMessage'],
      imageValidated: json['imageValidated'] ?? false,
      elevation: (json['elevation'] as num?)?.toDouble(),
      riskLevel: json['riskLevel'] as String?,
    );
  }
}

class ReportService {
  static const String _reportsKey = 'flood_reports';
  static const String _pendingReportsKey = 'pending_reports';
  
  // Singleton pattern
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  // In-memory cache of reports
  List<FloodReport> _reports = [];
  List<FloodReport> _pendingReports = [];
  
  // Flag to track if reports are being loaded
  bool _isLoading = false;
  
  // Getter for loading state
  bool get isLoading => _isLoading;
  
  // Getter for all reports
  List<FloodReport> get reports => List.unmodifiable(_reports);
  
  // Getter for pending reports
  List<FloodReport> get pendingReports => List.unmodifiable(_pendingReports);

  // Initialize the service
  Future<void> initialize() async {
    await _loadReports();
  }

  // Load reports from local storage
  Future<void> _loadReports() async {
    if (_isLoading) return;
    
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load submitted reports
      final reportsJson = prefs.getStringList(_reportsKey) ?? [];
      _reports = reportsJson
          .map((json) => FloodReport.fromJson(jsonDecode(json)))
          .toList();
      
      // Load pending reports
      final pendingReportsJson = prefs.getStringList(_pendingReportsKey) ?? [];
      _pendingReports = pendingReportsJson
          .map((json) => FloodReport.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Error loading reports: $e');
    } finally {
      _isLoading = false;
    }
  }

  // Save reports to local storage
  Future<void> _saveReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save submitted reports
      final reportsJson = _reports
          .map((report) => jsonEncode(report.toJson()))
          .toList();
      await prefs.setStringList(_reportsKey, reportsJson);
      
      // Save pending reports
      final pendingReportsJson = _pendingReports
          .map((report) => jsonEncode(report.toJson()))
          .toList();
      await prefs.setStringList(_pendingReportsKey, pendingReportsJson);
    } catch (e) {
      debugPrint('Error saving reports: $e');
    }
  }

  // Submit a new report
  Future<FloodReport> submitReport({
    required double latitude,
    required double longitude,
    required String description,
    required String severity,
    String? imagePath,
    bool imageValidated = false,
  }) async {
    // Create a new report with a unique ID
    final report = FloodReport(
      id: const Uuid().v4(),
      latitude: latitude,
      longitude: longitude,
      description: description,
      severity: severity,
      imagePath: imagePath,
      timestamp: DateTime.now(),
      imageValidated: imageValidated,
    );
    
    // Add to pending reports
    _pendingReports.add(report);
    await _saveReports();
    
    // Try to submit to server
    try {
      // TODO: Implement actual API call to submit report
      // For now, we'll simulate a network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate success (90% of the time)
      final isSuccess = DateTime.now().millisecondsSinceEpoch % 10 != 0;
      
      if (isSuccess) {
        // Mark as submitted and move to submitted reports
        final submittedReport = FloodReport(
          id: report.id,
          latitude: report.latitude,
          longitude: report.longitude,
          description: report.description,
          severity: report.severity,
          imagePath: report.imagePath,
          timestamp: report.timestamp,
          isSubmitted: true,
          imageValidated: report.imageValidated,
        );
        
        _pendingReports.removeWhere((r) => r.id == report.id);
        _reports.add(submittedReport);
        await _saveReports();
        
        // Trigger post-validation in the background
        _triggerPostValidation(submittedReport);
        
        return submittedReport;
      } else {
        // Simulate failure
        final failedReport = FloodReport(
          id: report.id,
          latitude: report.latitude,
          longitude: report.longitude,
          description: report.description,
          severity: report.severity,
          imagePath: report.imagePath,
          timestamp: report.timestamp,
          isSubmitted: false,
          errorMessage: 'Network error. Will retry later.',
          imageValidated: report.imageValidated,
        );
        
        // Update the pending report with error
        final index = _pendingReports.indexWhere((r) => r.id == report.id);
        if (index != -1) {
          _pendingReports[index] = failedReport;
          await _saveReports();
        }
        
        return failedReport;
      }
    } catch (e) {
      // Handle actual errors
      final failedReport = FloodReport(
        id: report.id,
        latitude: report.latitude,
        longitude: report.longitude,
        description: report.description,
        severity: report.severity,
        imagePath: report.imagePath,
        timestamp: report.timestamp,
        isSubmitted: false,
        errorMessage: 'Error: ${e.toString()}',
        imageValidated: report.imageValidated,
      );
      
      // Update the pending report with error
      final index = _pendingReports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        _pendingReports[index] = failedReport;
        await _saveReports();
      }
      
      return failedReport;
    }
  }

  // New method to trigger post-validation in the background
  Future<void> _triggerPostValidation(FloodReport report) async {
    try {
      // Fetch environmental data for the report's location
      final rainfall = await _fetchRainfall(report.latitude, report.longitude);
      final userReports = await _fetchUserReportsCount(report.latitude, report.longitude);
      final scpRiskLevel = await _fetchScpRiskLevel(report.latitude, report.longitude);
      final hasHistoricalFloodData = await _fetchHistoricalFloodData(report.latitude, report.longitude);
      
      // Calculate risk and update the report
      await processReportWithElevationAndRisk(
        report: report,
        geocodedLatLng: null,
        gpsLat: report.latitude,
        gpsLng: report.longitude,
        rainfall: rainfall,
        userReports: userReports,
        scpRiskLevel: scpRiskLevel,
        hasHistoricalFloodData: hasHistoricalFloodData,
      );
      
      // Update the report in storage with the risk score
      await _updateReportWithRisk(report);
    } catch (e) {
      debugPrint('Error during post-validation: $e');
      // Optionally, log or retry the post-validation
    }
  }

  // Helper methods to fetch environmental data (replace with actual API calls)
  Future<double> _fetchRainfall(double latitude, double longitude) async {
    // TODO: Implement actual API call to fetch rainfall
    return 0.0;
  }

  Future<int> _fetchUserReportsCount(double latitude, double longitude) async {
    // TODO: Implement actual API call to fetch user reports count
    return 0;
  }

  Future<String> _fetchScpRiskLevel(double latitude, double longitude) async {
    // TODO: Implement actual API call to fetch SCP risk level
    return "Normal";
  }

  Future<bool> _fetchHistoricalFloodData(double latitude, double longitude) async {
    // TODO: Implement actual API call to fetch historical flood data
    return false;
  }

  Future<void> _updateReportWithRisk(FloodReport report) async {
    // Update the report in storage with the risk score
    final index = _reports.indexWhere((r) => r.id == report.id);
    if (index != -1) {
      _reports[index] = report;
      await _saveReports();
    }
  }

  // Retry submitting a failed report
  Future<FloodReport> retrySubmission(String reportId) async {
    final report = _pendingReports.firstWhere((r) => r.id == reportId);
    
    // Remove from pending reports
    _pendingReports.removeWhere((r) => r.id == reportId);
    await _saveReports();
    
    // Try to submit again
    return submitReport(
      latitude: report.latitude,
      longitude: report.longitude,
      description: report.description,
      severity: report.severity,
      imagePath: report.imagePath,
    );
  }

  // Delete a report
  Future<void> deleteReport(String reportId) async {
    _reports.removeWhere((r) => r.id == reportId);
    _pendingReports.removeWhere((r) => r.id == reportId);
    await _saveReports();
  }

  // Save image to local storage
  Future<String?> saveImage(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final savedPath = '${directory.path}/$fileName';
      
      final file = File(imagePath);
      await file.copy(savedPath);
      
      return savedPath;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  // Convert a risk score (double) to a risk level (String)
  String riskScoreToLevel(double riskScore) {
    if (riskScore >= 0.7) return 'High';
    if (riskScore >= 0.4) return 'Medium';
    return 'Low';
  }

  Future<void> processReportWithElevationAndRisk({
    required FloodReport report,
    Map<String, double>? geocodedLatLng,
    double? gpsLat,
    double? gpsLng,
    required double rainfall,
    required int userReports,
    required String scpRiskLevel,
    required bool hasHistoricalFloodData,
  }) async {
    // 1. Fetch and set elevation
    await report.enrichWithElevation(
      geocodedLatLng: geocodedLatLng,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
    );

    // 2. Calculate risk using the elevation (default to 0.0 if null)
    final riskScore = calculateFloodRisk(
      rainfall: rainfall,
      elevation: report.elevation ?? 0.0,
      userReports: userReports,
      scpRiskLevel: scpRiskLevel,
      hasHistoricalFloodData: hasHistoricalFloodData,
    );

    // 3. Convert risk score to risk level and store it in the report
    report.riskLevel = riskScoreToLevel(riskScore);
    // Optionally, save or update the report in your database here
  }

  // Calculate flood risk based on various factors
  double calculateFloodRisk({
    required double rainfall,
    required double elevation,
    required int userReports,
    required String scpRiskLevel,
    required bool hasHistoricalFloodData,
  }) {
    // Base risk score starts at 0.0
    double riskScore = 0.0;

    // Rainfall contribution (higher rainfall increases risk)
    riskScore += rainfall * 0.1;

    // Elevation contribution (lower elevation increases risk)
    if (elevation < 10.0) {
      riskScore += 0.3;
    } else if (elevation < 50.0) {
      riskScore += 0.2;
    } else if (elevation < 100.0) {
      riskScore += 0.1;
    }

    // User reports contribution (more reports increase risk)
    riskScore += (userReports * 0.05).clamp(0.0, 0.2);

    // SCP risk level contribution
    switch (scpRiskLevel.toLowerCase()) {
      case 'high':
        riskScore += 0.3;
        break;
      case 'medium':
        riskScore += 0.2;
        break;
      case 'low':
        riskScore += 0.1;
        break;
      default:
        riskScore += 0.1;
    }

    // Historical flood data contribution
    if (hasHistoricalFloodData) {
      riskScore += 0.2;
    }

    // Normalize risk score to a value between 0.0 and 1.0
    return riskScore.clamp(0.0, 1.0);
  }
}

extension FloodReportElevation on FloodReport {
  /// Returns the best latitude/longitude for this report, preferring geocoded address if available.
  static Map<String, double>? selectBestLatLng({
    Map<String, double>? geocodedLatLng,
    double? gpsLat,
    double? gpsLng,
  }) {
    if (geocodedLatLng != null && geocodedLatLng['lat'] != null && geocodedLatLng['lng'] != null) {
      return {'lat': geocodedLatLng['lat']!, 'lng': geocodedLatLng['lng']!};
    } else if (gpsLat != null && gpsLng != null) {
      return {'lat': gpsLat, 'lng': gpsLng};
    }
    return null;
  }

  /// Fetches and sets elevation for this report using the best available lat/lon.
  Future<void> enrichWithElevation({
    Map<String, double>? geocodedLatLng,
    double? gpsLat,
    double? gpsLng,
  }) async {
    final bestLatLng = selectBestLatLng(
      geocodedLatLng: geocodedLatLng,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
    );
    if (bestLatLng != null) {
      final elevation = await ElevationService.fetchElevation(bestLatLng['lat']!, bestLatLng['lng']!);
      if (elevation != null) {
        // If your FloodReport has an elevation field, set it here
        // this.elevation = elevation;
        // If not, you may want to update your model to include it
      }
    }
  }
} 