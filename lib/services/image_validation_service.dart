import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cursortest/services/image_metadata_service.dart';

class ImageValidationResult {
  final bool isValid;
  final String? errorMessage;
  final double? blurScore;
  final double? waterColorScore;
  final bool hasValidResolution;
  final bool isNotBlurry;
  final bool containsWaterColors;
  final bool hasValidMetadata;
  final String? metadataError;

  ImageValidationResult({
    required this.isValid,
    this.errorMessage,
    this.blurScore,
    this.waterColorScore,
    this.hasValidResolution = false,
    this.isNotBlurry = false,
    this.containsWaterColors = false,
    this.hasValidMetadata = false,
    this.metadataError,
  });
}

class ImageValidationService {
  final _metadataService = ImageMetadataService();
  
  // Minimum required resolution (width x height)
  static const int minWidth = 800;
  static const int minHeight = 600;
  
  // Maximum file size in bytes (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;
  
  // Blur threshold (lower is blurrier)
  static const double blurThreshold = 100.0;
  
  // Water color similarity threshold (higher means more similar to water)
  static const double waterColorThreshold = 0.3;

  Future<Position> _getCurrentPosition() async {
    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<ImageValidationResult> validateImage(String imagePath) async {
    try {
      // Get current position
      final currentPosition = await _getCurrentPosition();

      // Check file size
      final file = File(imagePath);
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        return ImageValidationResult(
          isValid: false,
          errorMessage: 'Image file is too large. Maximum size is 5MB.',
        );
      }

      // Load and decode image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return ImageValidationResult(
          isValid: false,
          errorMessage: 'Could not decode image. Please try another image.',
        );
      }

      // Check resolution
      final hasValidResolution = image.width >= minWidth && image.height >= minHeight;
      if (!hasValidResolution) {
        return ImageValidationResult(
          isValid: false,
          errorMessage: 'Image resolution is too low. Minimum size is ${minWidth}x$minHeight pixels.',
          hasValidResolution: false,
        );
      }

      // Run validations in parallel for better performance
      final results = await Future.wait([
        _calculateBlurScore(image),
        _analyzeWaterColors(image),
        _metadataService.validateMetadata(imagePath, currentPosition),
      ]);
      
      final blurScore = results[0] as double;
      final waterColorScore = results[1] as double;
      final metadataResult = results[2] as ImageMetadataResult;
      
      final isNotBlurry = blurScore >= blurThreshold;
      final containsWaterColors = waterColorScore >= waterColorThreshold;
      final hasValidMetadata = metadataResult.isValid;
      
      // Determine overall validity
      final isValid = hasValidResolution && 
                     isNotBlurry && 
                     containsWaterColors && 
                     hasValidMetadata;
      
      String? errorMessage;
      
      if (!isNotBlurry && !containsWaterColors) {
        errorMessage = 'Image appears to be blurry and doesn\'t show clear signs of water.';
      } else if (!isNotBlurry) {
        errorMessage = 'Image appears to be blurry. Please take a clearer photo.';
      } else if (!containsWaterColors) {
        errorMessage = 'Image doesn\'t show clear signs of water. Please ensure the photo clearly shows the flood situation.';
      } else if (!hasValidMetadata) {
        errorMessage = metadataResult.errorMessage;
      }

      return ImageValidationResult(
        isValid: isValid,
        errorMessage: errorMessage,
        blurScore: blurScore,
        waterColorScore: waterColorScore,
        hasValidResolution: hasValidResolution,
        isNotBlurry: isNotBlurry,
        containsWaterColors: containsWaterColors,
        hasValidMetadata: hasValidMetadata,
        metadataError: metadataResult.errorMessage,
      );
    } catch (e) {
      return ImageValidationResult(
        isValid: false,
        errorMessage: 'Error validating image: ${e.toString()}',
      );
    }
  }

  Future<double> _calculateBlurScore(img.Image image) async {
    // Use compute for better performance
    return compute(_calculateBlurScoreInIsolate, image);
  }
  
  static double _calculateBlurScoreInIsolate(img.Image image) {
    // Convert to grayscale
    final grayscale = img.grayscale(image);
    
    // Resize for faster processing if image is very large
    final resized = image.width > 1000 || image.height > 1000
        ? img.copyResize(grayscale, width: 1000, height: (1000 * grayscale.height / grayscale.width).round())
        : grayscale;
    
    // Calculate Laplacian variance
    double variance = 0;
    int count = 0;
    
    // Sample pixels for better performance
    final sampleStep = resized.width > 500 ? 2 : 1;
    
    for (int y = sampleStep; y < resized.height - sampleStep; y += sampleStep) {
      for (int x = sampleStep; x < resized.width - sampleStep; x += sampleStep) {
        final pixel = resized.getPixel(x, y);
        final p1 = resized.getPixel(x - sampleStep, y);
        final p2 = resized.getPixel(x + sampleStep, y);
        final p3 = resized.getPixel(x, y - sampleStep);
        final p4 = resized.getPixel(x, y + sampleStep);
        
        // Calculate Laplacian using pixel luminance values
        final laplacian = (pixel.luminance * 4 - p1.luminance - p2.luminance - p3.luminance - p4.luminance).abs();
        variance += laplacian * laplacian;
        count++;
      }
    }
    
    return variance / count;
  }

  Future<double> _analyzeWaterColors(img.Image image) async {
    // Use compute for better performance
    return compute(_analyzeWaterColorsInIsolate, image);
  }
  
  static double _analyzeWaterColorsInIsolate(img.Image image) {
    // Resize for faster processing
    final resized = img.copyResize(image, width: 200, height: 200);
    
    int waterColorPixels = 0;
    int totalPixels = 0;
    
    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        
        // Convert to HSV for better color analysis
        final hsv = _rgbToHsv(
          pixel.r.toInt().clamp(0, 255),
          pixel.g.toInt().clamp(0, 255),
          pixel.b.toInt().clamp(0, 255),
        );
        final h = hsv[0]; // Hue
        final s = hsv[1]; // Saturation
        final v = hsv[2]; // Value (brightness)
        
        // Water detection rules:
        // 1. Blue-ish hues (180-260 degrees)
        // 2. Gray tones (low saturation, medium-high value)
        // 3. Dark blue/gray (lower value, blue hue)
        bool isWaterColor = false;
        
        // Blue water
        if (h >= 180 && h <= 260 && s >= 0.2) {
          isWaterColor = true;
        }
        // Gray water (muddy)
        else if (s < 0.2 && v >= 0.2 && v <= 0.8) {
          isWaterColor = true;
        }
        // Dark water
        else if (pixel.b > pixel.r && pixel.b > pixel.g && v < 0.5) {
          isWaterColor = true;
        }
        
        if (isWaterColor) {
          waterColorPixels++;
        }
        
        totalPixels++;
      }
    }
    
    return waterColorPixels / totalPixels;
  }
  
  // Helper function to convert RGB to HSV
  static List<double> _rgbToHsv(int r, int g, int b) {
    // Normalize RGB values to 0-1 range
    double red = (r.clamp(0, 255) / 255);
    double green = (g.clamp(0, 255) / 255);
    double blue = (b.clamp(0, 255) / 255);
    
    double max = [red, green, blue].reduce((curr, next) => curr > next ? curr : next);
    double min = [red, green, blue].reduce((curr, next) => curr < next ? curr : next);
    double delta = max - min;
    
    // Calculate hue (0-360)
    double hue = 0;
    if (delta != 0) {
      if (max == red) {
        hue = ((green - blue) / delta) % 6;
      } else if (max == green) {
        hue = (blue - red) / delta + 2;
      } else {
        hue = (red - green) / delta + 4;
      }
      
      hue *= 60;
      if (hue < 0) hue += 360;
    }
    
    // Calculate saturation (0-1)
    double saturation = max == 0 ? 0 : delta / max;
    
    // Value (0-1)
    double value = max;
    
    return [hue, saturation, value];
  }
} 