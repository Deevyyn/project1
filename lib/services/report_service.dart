import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
        );
        
        _pendingReports.removeWhere((r) => r.id == report.id);
        _reports.add(submittedReport);
        await _saveReports();
        
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
} 