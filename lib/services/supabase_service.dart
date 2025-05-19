import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:cursortest/models/validation_status.dart';
import 'package:cursortest/services/flood_risk_service.dart';
import 'package:cursortest/services/weather_service.dart';

const Uuid _uuid = Uuid();

/// Service class for handling all Supabase related operations
/// This includes flood report submission, image uploads, and data retrieval
class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Get instance of Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;
  final WeatherService _weatherService = WeatherService();
  
  // Constants
  static const String _reportImagesStorageBucket = 'flood-report-images';
  static const String _floodReportsTable = 'flood_reports';

  /// Uploads an image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String?> uploadImage(File imageFile) async {
    try {
      final String fileExt = path.extension(imageFile.path);
      // Add 'public/' prefix to the filename to match storage policy
      final fileName = 'public/${_uuid.v4()}$fileExt';
      
      debugPrint('Uploading image to: $fileName');
      
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
      
      debugPrint('Image uploaded successfully. Public URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Submits a flood report to Supabase
  /// Returns the submitted report data if successful
  /// Submits a new flood report to the database
  /// Returns the created report if successful, null otherwise
  Future<Map<String, dynamic>?> submitFloodReport({
    required String description,
    required String location,
    required double latitude,
    required double longitude,
    required String severity,
    String? riskLevel,
    String? imageUrl,
    bool imageValidated = false,
    double? elevation,
    String? scpRiskLevel,
    bool floodZoneMatch = false,
  }) async {
    try {
      final data = {
        'description': description,
        'location_description': location,
        'latitude': latitude,
        'longitude': longitude,
        'severity': severity,
        'image_url': imageUrl,
        'image_validated': imageValidated,
        'validation_status': ['pending'],
        'report_source': 'app',
        'is_validated': false,
        'timestamp': DateTime.now().toIso8601String(),
        'validation_data': {
          'risk_level': riskLevel,
          'elevation': elevation,
          'user_reports_count': 0, // Will be updated in post-validation
          'scp_risk_level': scpRiskLevel,
          'flood_zone_match': floodZoneMatch,
          'risk_score': null,
          'rainfall': null,
        },
      };

      // Remove null values to avoid database errors
      data.removeWhere((key, value) => value == null);

      // Insert and get the new report
      final response = await _supabase
          .from(_floodReportsTable)
          .insert(data)
          .select()
          .single();

      // Start post-validation in the background
      _performPostValidation(response['id']);
      
      return response;
    } catch (e) {
      debugPrint('Error submitting flood report: $e');
      rethrow;
    }
  }

  /// Retrieves all flood reports from Supabase
  Future<List<Map<String, dynamic>>> getFloodReports() async {
    try {
      final response = await _supabase
          .from(_floodReportsTable)
          .select()
          .order('timestamp', ascending: false);
      
      // Convert to list and process each report
      final reports = List<Map<String, dynamic>>.from(response);
      
      // Ensure each report has a properly formatted validation_data and timestamp
      return reports.map((report) {
        // Ensure timestamp is properly formatted
        if (report['timestamp'] == null) {
          report['timestamp'] = DateTime.now().toIso8601String();
        } else if (report['timestamp'] is String) {
          // If it's already a string, ensure it's in ISO 8601 format
          try {
            DateTime.parse(report['timestamp']);
          } catch (e) {
            debugPrint('Invalid timestamp format for report ${report['id']}: ${report['timestamp']}');
            report['timestamp'] = DateTime.now().toIso8601String();
          }
        } else if (report['timestamp'] is DateTime) {
          // Convert DateTime to ISO 8601 string if needed
          report['timestamp'] = (report['timestamp'] as DateTime).toIso8601String();
        }
        
        final validationData = report['validation_data'] ?? {};
        
        // Move any legacy fields to validation_data if they exist at the root level
        final legacyFields = {
          'elevation': report['elevation'],
          'risk_level': report['risk_level'],
          'scp_risk_level': report['scp_risk_level'],
          'flood_zone_match': report['flood_zone_match'],
          'user_reports_count': report['user_reports_count'],
          'risk_score': report['risk_score'],
        };
        
        // Only include non-null legacy fields
        legacyFields.removeWhere((key, value) => value == null);
        
        if (legacyFields.isNotEmpty) {
          report['validation_data'] = {
            ...validationData,
            ...legacyFields,
          };
          
          // Remove the legacy fields from the root
          report.remove('elevation');
          report.remove('risk_level');
          report.remove('scp_risk_level');
          report.remove('flood_zone_match');
          report.remove('user_reports_count');
          report.remove('risk_score');
        }
        
        return report;
      }).toList();
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
      }).map((report) {
        // Ensure each report has properly formatted validation_data
        final validationData = report['validation_data'] ?? {};
        
        // Move any legacy fields to validation_data if they exist at the root level
        final legacyFields = {
          'elevation': report['elevation'],
          'risk_level': report['risk_level'],
          'scp_risk_level': report['scp_risk_level'],
          'flood_zone_match': report['flood_zone_match'],
          'user_reports_count': report['user_reports_count'],
          'risk_score': report['risk_score'],
        };
        
        // Only include non-null legacy fields
        legacyFields.removeWhere((key, value) => value == null);
        
        if (legacyFields.isNotEmpty) {
          report['validation_data'] = {
            ...validationData,
            ...legacyFields,
          };
          
          // Remove the legacy fields from the root
          report.remove('elevation');
          report.remove('risk_level');
          report.remove('scp_risk_level');
          report.remove('flood_zone_match');
          report.remove('user_reports_count');
          report.remove('risk_score');
        }
        
        return report;
      }).toList();
    } catch (e) {
      debugPrint('Error retrieving nearby flood reports: $e');
      return [];
    }
  }

  /// Counts the number of validated reports within a specified radius of the given coordinates
  /// Counts the number of validated reports within a specified radius of the given coordinates
  /// [reportId] - The ID of the current report to exclude from the count
  /// [latitude] - The latitude of the location to check
  /// [longitude] - The longitude of the location to check
  /// [radiusKm] - The radius in kilometers to search for nearby reports (default: 2.0km)
  /// Counts the number of validated reports within a specified radius of the given coordinates
  /// [reportId] - The ID of the current report to exclude from the count
  /// [latitude] - The latitude of the location to check
  /// [longitude] - The longitude of the location to check
  /// [radiusKm] - The radius in kilometers to search for nearby reports (default: 2.0km)
  Future<int> countNearbyValidatedReports(
    String reportId,
    double latitude,
    double longitude, {
    double radiusKm = 2.0,
  }) async {
    try {
      debugPrint('🔍 Counting nearby validated reports for report $reportId');
      
      // Convert km to meters for the RPC call
      final radiusMeters = (radiusKm * 1000).round();
      
      final response = await _supabase.rpc(
        'get_nearby_reports',
        params: {
          'lat': latitude,
          'lng': longitude,
          'radius_meters': radiusMeters,
          'exclude_id': reportId,
        },
      );
      
      final count = response.length;
      debugPrint('✅ Found $count nearby validated reports within ${radiusMeters}m');
      
      return count;
    } catch (e, stackTrace) {
      debugPrint('❌ Error counting nearby reports: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Log the error to the server if needed
      // await _logErrorToServer('countNearbyValidatedReports', e, stackTrace);
      
      // Return 0 to allow the process to continue
      return 0;
    }
  }

  /// Updates the status of a flood report
  /// Updates the validation status of a report
  Future<void> updateReportValidationStatus({
    required String reportId,
    required ValidationStatus status,
    Map<String, dynamic>? validationData,
    String? error,
  }) async {
    try {
      // Get existing validation data
      final response = await _supabase
          .from(_floodReportsTable)
          .select('validation_data')
          .eq('id', reportId)
          .single();
      
      // Get existing validation data or create new
      final existingData = response['validation_data'] ?? {};
      
      // Prepare validation data update
      final validationDataUpdate = {
        ...existingData,
        if (validationData != null) ...{
          'risk_score': validationData['score'],
          'risk_level': validationData['riskLevel']?.toString().toLowerCase(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      };

      final updateData = <String, dynamic>{
        'validation_status': [status.name],
        'is_validated': status == ValidationStatus.completed,
        'validation_data': validationDataUpdate,
      };

      // Add error if present
      if (error != null) {
        updateData['validation_error'] = error.length > 255 ? error.substring(0, 255) : error;
      }

      // Remove null values to avoid database errors
      updateData.removeWhere((key, value) => value == null);

      await _supabase
          .from(_floodReportsTable)
          .update(updateData)
          .eq('id', reportId);
    } catch (e) {
      debugPrint('Error updating report validation status: $e');
      rethrow;
    }
  }

  /// Performs post-validation for a report
  /// Performs post-validation for a report
  Future<void> _performPostValidation(String reportId) async {
    try {
      debugPrint('🔄 Starting post-validation for report: $reportId');
      
      // Mark as processing
      await _supabase.from(_floodReportsTable).update({
        'validation_status': ['processing'],
      }).eq('id', reportId);

      // Get the full report data with validation_data
      final response = await _supabase
          .from(_floodReportsTable)
          .select()
          .eq('id', reportId)
          .single();
      
      debugPrint('📍 Report location: ${response['latitude']}, ${response['longitude']}');

      // Get existing validation data or create new
      final existingData = response['validation_data'] ?? {};
      
      // Count nearby validated reports (excluding the current report)
      final nearbyReports = await countNearbyValidatedReports(
        reportId,  // Pass the reportId to exclude it from the count
        response['latitude'] as double,
        response['longitude'] as double,
      );
      
      debugPrint('🔍 Found $nearbyReports nearby validated reports');

      // Get weather data for the report location
      final weatherData = await _weatherService.getWeatherForLocation(
        response['latitude'] as double,
        response['longitude'] as double,
      );

      // Update the validation data with the nearby reports count and weather data
      final updatedValidationData = {
        ...existingData,
        'user_reports_count': nearbyReports,
        'rainfall': weatherData.rainfall,
        'humidity': weatherData.humidity,
        'weather_timestamp': DateTime.now().toIso8601String(),
      };

      // Update the report with the updated validation data
      await _supabase
          .from(_floodReportsTable)
          .update({
            'validation_data': updatedValidationData,
          })
          .eq('id', reportId);

      // Perform validation with updated report count
      final riskData = await FloodRiskService().getDetailedFloodRisk(
        latitude: response['latitude'] as double,
        longitude: response['longitude'] as double,
        elevation: (existingData['elevation'] as num?)?.toDouble() ?? 0.0,
        userReports: nearbyReports,
        scpRiskLevel: (existingData['scp_risk_level'] as String?) ?? 'Normal',
        floodZoneMatch: (existingData['flood_zone_match'] as bool?) ?? false,
      );
      
      debugPrint('📊 Calculated risk level: ${riskData['riskLevel']} (Score: ${riskData['score']})');

      // Update with validation results
      await updateReportValidationStatus(
        reportId: reportId,
        status: ValidationStatus.completed,
        validationData: riskData,
      );
      
      debugPrint('✅ Successfully validated report: $reportId');
    } catch (e) {
      final errorMsg = 'Error in post-validation: $e';
      debugPrint('❌ $errorMsg');
      
      // Get existing validation data
      final response = await _supabase
          .from(_floodReportsTable)
          .select('validation_data')
          .eq('id', reportId)
          .single();
      
      // Update validation data with error
      final updatedValidationData = {
        ...(response['validation_data'] ?? {}),
        'error': errorMsg,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Mark as failed if there's an error
      await _supabase.from(_floodReportsTable).update({
        'validation_status': ['failed'],
        'validation_error': errorMsg.length <= 255 ? errorMsg : errorMsg.substring(0, 255),
        'is_validated': false,
        'validation_data': updatedValidationData,
      }).eq('id', reportId);
      
      // Re-throw to allow callers to handle the error if needed
      rethrow;
    }
  }
}
