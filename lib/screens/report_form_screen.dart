import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cursortest/utils/theme.dart';
import 'package:cursortest/services/location_service.dart';
import 'package:cursortest/services/image_validation_service.dart';
import 'package:cursortest/services/supabase_service.dart';
import 'package:cursortest/services/report_service.dart';

import 'dart:io';
import 'package:cursortest/widgets/custom_toast.dart';
import 'package:cursortest/screens/report_success_screen.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();
  final _imageValidationService = ImageValidationService();
  final _supabaseService = SupabaseService();
  final _reportService = ReportService(); // Keep for local backup/post-validation
  
  // Form data
  String _description = '';
  String _severity = 'Medium';
  String? _imagePath;
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isValidatingImage = false;
  bool _isSubmitting = false;
  String? _error;
  ImageValidationResult? _imageValidationResult;
  
  // Step tracking
  int _currentStep = 0;
  final int _totalSteps = 3;
  
  // Character limit for description
  final int _descriptionLimit = 500;
  int _descriptionLength = 0;
  
  // Location step data
  String? _locationDescription;
  double? _latitude;
  double? _longitude;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      } else {
        _showLocationError();
      }
    } catch (e) {
      _showLocationError();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showLocationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: const CustomToast(
          message: 'Could not get your location. Please enable location services.',
          type: ToastType.error,
        ),
      ),
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (!mounted) return;
    
    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _isValidatingImage = true;
        _imageValidationResult = null;
      });
      
      // Validate the image
      final validationResult = await _imageValidationService.validateImage(image.path);
      
      setState(() {
        _imageValidationResult = validationResult;
        _isValidatingImage = false;
      });
      
      if (!validationResult.isValid) {
        _showImageValidationError(validationResult.errorMessage ?? 'Invalid image');
      }
    }
  }
  
  void _showImageValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: CustomToast(
          message: message,
          type: ToastType.error,
        ),
      ),
    );
  }
  
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submitForm();
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      double? finalLatitude;
      double? finalLongitude;

      if (_currentPosition != null) {
        // Use GPS coordinates
        finalLatitude = _currentPosition!.latitude;
        finalLongitude = _currentPosition!.longitude;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            content: const CustomToast(
              message: 'Location is required. Please enable location services.',
              type: ToastType.error,
            ),
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Process and upload image if provided
      String? imageUrl;
      if (_imagePath != null) {
        final imageFile = File(_imagePath!);
        // Upload image to Supabase storage
        imageUrl = await _supabaseService.uploadImage(imageFile);
        
        if (imageUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              content: const CustomToast(
                message: 'Failed to upload image. Please try again.',
                type: ToastType.error,
              ),
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      // Submit report to Supabase
      final reportData = await _supabaseService.submitFloodReport(
        description: _description,
        location: (_locationDescription?.trim().isNotEmpty ?? false) ? _locationDescription!.trim() : 'GPS Location',
        latitude: finalLatitude!,
        longitude: finalLongitude!,
        severity: _severity,
        riskLevel: _severity, // Use severity as initial risk level
        imageUrl: imageUrl,
        imageValidated: _imageValidationResult?.isValid ?? false,
        elevation: _currentPosition?.altitude,
        scpRiskLevel: 'Normal', // Default value, will be updated in validation
        floodZoneMatch: false, // Will be checked in validation
      );
      
      if (reportData == null) {
        throw Exception('Failed to submit report to database');
      }
      
      // Also save locally for backup and post-validation
      await _reportService.submitReport(
        latitude: finalLatitude,
        longitude: finalLongitude,
        description: _description,
        severity: _severity,
        imagePath: _imagePath,
        imageValidated: _imageValidationResult?.isValid ?? false,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      // Show success message
      String? warningMessage;
      if (!(_imageValidationResult?.isValid ?? false) && _imagePath != null) {
        warningMessage = 'Image validation failed. Report submitted with unverified image.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          content: const CustomToast(
            message: 'Report submitted successfully',
            type: ToastType.success,
          ),
        ),
      );

      // Navigate to the success screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => ReportSuccessScreen(warningMessage: warningMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.toString();
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          content: CustomToast(
            message: 'Error submitting report: ${e.toString()}',
            type: ToastType.error,
          ),
        ),
      );
    }
  }
  
  Widget _buildValidationResultTile({
    required String title,
    required bool isValid,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid ? AppTheme.successGreen : AppTheme.errorRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.darkBlue,
                  ),
                ),
                Text(
                  message,
                  style: AppTheme.bodyTextSmall.copyWith(
                    color: isValid ? AppTheme.successGreen : AppTheme.errorRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImagePreview() {
    if (_isValidatingImage) {
      return Card(
        color: AppTheme.accentWhite,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Validating image...',
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_imagePath != null) {
      return Card(
        color: AppTheme.accentWhite,
        child: Column(
          children: [
            Stack(
              children: [
                Image.file(
                  File(_imagePath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (_imageValidationResult != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _imageValidationResult!.isValid
                            ? Color.fromRGBO(AppTheme.successGreen.red, AppTheme.successGreen.green, AppTheme.successGreen.blue, 0.8)
                            : Color.fromRGBO(AppTheme.errorRed.red, AppTheme.errorRed.green, AppTheme.errorRed.blue, 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _imageValidationResult!.isValid
                                ? Icons.check_circle
                                : Icons.error,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _imageValidationResult!.isValid ? 'Valid' : 'Invalid',
                            style: AppTheme.buttonText.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (_imageValidationResult != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildValidationResultTile(
                      title: 'Resolution',
                      isValid: _imageValidationResult!.hasValidResolution,
                      message: _imageValidationResult!.hasValidResolution
                          ? 'Image resolution is sufficient'
                          : 'Image resolution is too low',
                    ),
                    _buildValidationResultTile(
                      title: 'Blur',
                      isValid: _imageValidationResult!.isNotBlurry,
                      message: _imageValidationResult!.isNotBlurry
                          ? 'Image is clear'
                          : 'Image is too blurry',
                    ),
                    if (_imageValidationResult!.containsWaterColors)
                      _buildValidationResultTile(
                        title: 'Water Detection',
                        isValid: true,
                        message: 'Water detected in image',
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Retake Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _imagePath = null;
                          _imageValidationResult = null;
                        });
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return Card(
      color: AppTheme.accentWhite,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'Add a photo of the flood',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will help authorities assess the situation',
              textAlign: TextAlign.center,
              style: AppTheme.bodyTextSmall.copyWith(
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: _nextStep,
      onStepCancel: _previousStep,
      controlsBuilder: (context, details) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0)
                const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.mediumGray,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accentWhite,
                          ),
                        )
                      : Text(_currentStep == _totalSteps - 1 ? 'Submit' : 'Next'),
                ),
              ),
            ],
          ),
        );
      },
      steps: [
        Step(
          title: Text(
            'Location',
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.darkBlue,
            ),
          ),
          content: _isLoading
              ? Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Getting your location...',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.darkBlue,
                        ),
                      ),
                    ],
                  ),
                )
              : _currentPosition != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Details',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Location',
                            hintText: 'e.g., Ugbowo Main Road',
                            filled: true,
                            fillColor: AppTheme.accentWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                          style: AppTheme.bodyText.copyWith(
                            color: AppTheme.darkBlue,
                          ),
                          onSaved: (value) {
                            _locationDescription = value?.trim() ?? '';
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your location';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                enabled: false,
                                controller: TextEditingController(text: _latitude?.toStringAsFixed(6) ?? 'Getting location...'),
                                decoration: InputDecoration(
                                  labelText: 'Latitude',
                                  filled: true,
                                  fillColor: AppTheme.accentWhite,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                enabled: false,
                                controller: TextEditingController(text: _longitude?.toStringAsFixed(6) ?? 'Getting location...'),
                                decoration: InputDecoration(
                                  labelText: 'Longitude',
                                  filled: true,
                                  fillColor: AppTheme.accentWhite,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Get Current Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 48,
                          color: AppTheme.errorRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Could not get your location',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.errorRed,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please enable location services and try again.',
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyText.copyWith(
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: Text(
                'Details',
                style: AppTheme.headingSmall.copyWith(
                  color: AppTheme.darkBlue,
                ),
              ),
          content: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the flood situation...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.mediumGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.mediumGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                    ),
                    counterText: '$_descriptionLength/$_descriptionLimit characters',
                    counterStyle: AppTheme.bodyTextSmall.copyWith(
                      color: AppTheme.darkGray,
                    ),
                    filled: true,
                    fillColor: AppTheme.accentWhite,
                  ),
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.darkBlue,
                  ),
                  maxLines: 5,
                  maxLength: _descriptionLimit,
                  onChanged: (value) {
                    setState(() {
                      _descriptionLength = value.length;
                    });
                  },
                  onSaved: (value) {
                    _description = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Severity Level',
                    labelStyle: AppTheme.bodyText.copyWith(
                      color: AppTheme.darkBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.mediumGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.mediumGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                    ),
                    filled: true,
                    fillColor: AppTheme.accentWhite,
                  ),
                  value: _severity,
                  items: const [
                    DropdownMenuItem(
                      value: 'Low',
                      child: Text('Low'),
                    ),
                    DropdownMenuItem(
                      value: 'Medium',
                      child: Text('Medium'),
                    ),
                    DropdownMenuItem(
                      value: 'High',
                      child: Text('High'),
                    ),
                    DropdownMenuItem(
                      value: 'Critical',
                      child: Text('Critical'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _severity = value ?? 'Medium';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select a severity level';
                    }
                    return null;
                  },
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.darkBlue,
                  ),
                ),
              ],
            ),
          ),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: Text(
            'Photo',
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.darkBlue,
            ),
          ),
          content: _buildImagePreview(),
          isActive: _currentStep >= 2,
          state: StepState.indexed,
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.accentWhite,
      appBar: AppBar(
        title: Text(
          'Report Flood',
          style: AppTheme.headingMedium.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: _buildStepIndicator(),
    );
  }
} 