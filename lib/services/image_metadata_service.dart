import 'dart:io';
import 'package:exif/exif.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class ImageMetadataResult {
  final bool isValid;
  final String? errorMessage;
  final DateTime? captureTime;
  final Position? imageLocation;
  final Map<String, dynamic>? exifData;
  final bool hasValidTimestamp;
  final bool hasValidLocation;
  final bool locationMatchesCurrent;

  ImageMetadataResult({
    required this.isValid,
    this.errorMessage,
    this.captureTime,
    this.imageLocation,
    this.exifData,
    this.hasValidTimestamp = false,
    this.hasValidLocation = false,
    this.locationMatchesCurrent = false,
  });
}

class ImageMetadataService {
  // Maximum time difference between image capture and report submission (24 hours)
  static const Duration maxTimeDifference = Duration(hours: 24);
  
  // Maximum distance between image location and report location (100 meters)
  static const double maxLocationDifference = 100.0;

  Future<ImageMetadataResult> validateMetadata(String imagePath, Position currentPosition) async {
    try {
      // Read EXIF data
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final exifData = await readExifFromBytes(bytes);
      
      if (exifData.isEmpty) {
        return ImageMetadataResult(
          isValid: false,
          errorMessage: 'No EXIF data found in the image.',
        );
      }

      // Extract and validate timestamp
      final captureTime = _extractCaptureTime(exifData);
      final hasValidTimestamp = _validateTimestamp(captureTime);
      
      // Extract and validate location
      final imageLocation = _extractLocation(exifData);
      final hasValidLocation = imageLocation != null;
      
      // Compare with current location if both are available
      bool locationMatchesCurrent = false;
      if (hasValidLocation) {
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          imageLocation.latitude,
          imageLocation.longitude,
        );
        locationMatchesCurrent = distance <= maxLocationDifference;
      }

      // Determine overall validity
      final isValid = hasValidTimestamp && (hasValidLocation ? locationMatchesCurrent : true);
      String? errorMessage;
      
      if (!hasValidTimestamp) {
        errorMessage = 'Image capture time is too old or invalid. Please take a recent photo.';
      } else if (hasValidLocation && !locationMatchesCurrent) {
        errorMessage = 'Image location doesn\'t match your current location. Please ensure you\'re reporting from the correct location.';
      }

      return ImageMetadataResult(
        isValid: isValid,
        errorMessage: errorMessage,
        captureTime: captureTime,
        imageLocation: imageLocation,
        exifData: exifData,
        hasValidTimestamp: hasValidTimestamp,
        hasValidLocation: hasValidLocation,
        locationMatchesCurrent: locationMatchesCurrent,
      );
    } catch (e) {
      return ImageMetadataResult(
        isValid: false,
        errorMessage: 'Error validating image metadata: ${e.toString()}',
      );
    }
  }

  DateTime? _extractCaptureTime(Map<String, IfdTag> exifData) {
    try {
      // Try different EXIF tags for capture time
      final dateTimeOriginal = exifData['EXIF DateTimeOriginal'];
      final dateTimeDigitized = exifData['EXIF DateTimeDigitized'];
      final dateTime = exifData['Image DateTime'];
      
      final dateTimeStr = dateTimeOriginal?.printable ?? 
                         dateTimeDigitized?.printable ?? 
                         dateTime?.printable;
      
      if (dateTimeStr != null) {
        // Parse EXIF date format (YYYY:MM:DD HH:MM:SS)
        final parts = dateTimeStr.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split(':');
          final timeParts = parts[1].split(':');
          
          if (dateParts.length == 3 && timeParts.length == 3) {
            return DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
              int.parse(timeParts[2]),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing capture time: $e');
    }
    
    return null;
  }

  bool _validateTimestamp(DateTime? captureTime) {
    if (captureTime == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(captureTime);
    
    return difference <= maxTimeDifference && difference.isNegative == false;
  }

  Position? _extractLocation(Map<String, IfdTag> exifData) {
    try {
      final gpsLatitude = exifData['GPS GPSLatitude'];
      final gpsLatitudeRef = exifData['GPS GPSLatitudeRef'];
      final gpsLongitude = exifData['GPS GPSLongitude'];
      final gpsLongitudeRef = exifData['GPS GPSLongitudeRef'];
      
      if (gpsLatitude != null && gpsLongitude != null) {
        final latitude = _parseGPSCoordinate(
          gpsLatitude.printable,
          gpsLatitudeRef?.printable ?? 'N',
        );
        
        final longitude = _parseGPSCoordinate(
          gpsLongitude.printable,
          gpsLongitudeRef?.printable ?? 'E',
        );
        
        if (latitude != null && longitude != null) {
          return Position(
            latitude: latitude,
            longitude: longitude,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
        }
      }
    } catch (e) {
      debugPrint('Error parsing GPS coordinates: $e');
    }
    
    return null;
  }

  double? _parseGPSCoordinate(String value, String ref) {
    try {
      // GPS coordinates are typically in format "deg/1,min/1,sec/1"
      final parts = value.split(',');
      if (parts.length >= 3) {
        double degrees = 0.0;
        double minutes = 0.0;
        double seconds = 0.0;

        // Parse degrees
        final degParts = parts[0].trim().split('/');
        if (degParts.length == 2) {
          degrees = double.parse(degParts[0]) / double.parse(degParts[1]);
        }

        // Parse minutes
        final minParts = parts[1].trim().split('/');
        if (minParts.length == 2) {
          minutes = double.parse(minParts[0]) / double.parse(minParts[1]);
        }

        // Parse seconds
        final secParts = parts[2].trim().split('/');
        if (secParts.length == 2) {
          seconds = double.parse(secParts[0]) / double.parse(secParts[1]);
        }

        var coordinate = degrees + (minutes / 60) + (seconds / 3600);
        
        // Apply hemisphere reference
        if (ref == 'S' || ref == 'W') {
          coordinate = -coordinate;
        }
        
        return coordinate;
      }
    } catch (e) {
      debugPrint('Error parsing GPS coordinate value: $e');
    }
    
    return null;
  }
} 