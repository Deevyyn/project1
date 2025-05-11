import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Service class for handling all Supabase related operations
/// This includes flood report submission, image uploads, and data retrieval
class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Get instance of Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Constants
  static const String _reportImagesStorageBucket = 'report_images';
  static const String _floodReportsTable = 'flood_reports';

  /// Uploads an image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String?> uploadImage(File imageFile) async {
    try {
      final String fileExt = path.extension(imageFile.path);
      final fileName = '${const Uuid().v4()}$fileExt';
      
      // Upload the file to Supabase Storage
      await _supabase
          .storage
          .from(_reportImagesStorageBucket)
          .upload(fileName, imageFile);
      
      // Get the public URL for the file
      final imageUrl = _supabase
          .storage
          .from(_reportImagesStorageBucket)
          .getPublicUrl(fileName);
      
      debugPrint('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Submits a flood report to Supabase
  /// Returns the submitted report data if successful
  Future<Map<String, dynamic>?> submitFloodReport({
    required String description,
    required String location,
    required double latitude,
    required double longitude,
    required String severity,
    String? riskLevel,
    String? imageUrl,
    bool imageValidated = false,
  }) async {
    try {
      final reportData = {
        'description': description,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'severity': severity,
        'risk_level': riskLevel ?? 'Medium',
        'image_url': imageUrl,
        'image_validated': imageValidated,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'submitted',
      };

      final response = await _supabase
          .from(_floodReportsTable)
          .insert(reportData)
          .select();
      
      if (response.isNotEmpty) {
        debugPrint('Flood report submitted successfully: ${response[0]}');
        return response[0];
      }
      
      return null;
    } catch (e) {
      debugPrint('Error submitting flood report: $e');
      return null;
    }
  }

  /// Retrieves all flood reports from Supabase
  Future<List<Map<String, dynamic>>> getFloodReports() async {
    try {
      final response = await _supabase
          .from(_floodReportsTable)
          .select()
          .order('timestamp', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error retrieving flood reports: $e');
      return [];
    }
  }

  /// Retrieves flood reports within a specific radius of a location
  Future<List<Map<String, dynamic>>> getNearbyFloodReports({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      // Note: This is a simplified implementation
      // In a production app, you would use PostGIS or a similar spatial database
      // Here we're just getting all reports and filtering them manually
      final allReports = await getFloodReports();
      
      // Filter reports based on approximate distance
      // (This is not accurate for large distances but works for small areas)
      const double latDegPerKm = 0.009;
      const double lngDegPerKm = 0.009;
      
      final latDiff = latDegPerKm * radiusKm;
      final lngDiff = lngDegPerKm * radiusKm;
      
      return allReports.where((report) {
        final reportLat = report['latitude'] as double;
        final reportLng = report['longitude'] as double;
        
        return (reportLat >= latitude - latDiff &&
                reportLat <= latitude + latDiff &&
                reportLng >= longitude - lngDiff &&
                reportLng <= longitude + lngDiff);
      }).toList();
    } catch (e) {
      debugPrint('Error retrieving nearby flood reports: $e');
      return [];
    }
  }

  /// Updates the status of a flood report
  Future<bool> updateReportStatus(String reportId, String status) async {
    try {
      await _supabase
          .from(_floodReportsTable)
          .update({'status': status})
          .eq('id', reportId);
      
      return true;
    } catch (e) {
      debugPrint('Error updating report status: $e');
      return false;
    }
  }

  /// Test function to demonstrate report submission functionality
  Future<void> testReportSubmission() async {
    try {
      // Simulate submitting a test flood report
      final testReport = await submitFloodReport(
        description: 'Test flood report',
        location: 'Test Location',
        latitude: 9.0820,
        longitude: 8.6753,
        severity: 'Medium',
        riskLevel: 'Medium',
        imageUrl: 'https://example.com/test-image.jpg',
        imageValidated: true,
      );
      
      debugPrint('Test report submission result: $testReport');
    } catch (e) {
      debugPrint('Error in test report submission: $e');
    }
  }
}
