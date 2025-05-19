import 'package:flutter/material.dart';

/// Represents the different states of report validation
enum ValidationStatus {
  pending,     // Initial state, waiting to be processed
  processing,  // Currently being validated
  completed,   // Successfully validated
  failed,      // Validation failed
}

extension ValidationStatusExtension on ValidationStatus {
  static ValidationStatus fromString(String value) {
    return ValidationStatus.values.firstWhere(
      (e) => e.toString() == 'ValidationStatus.$value' || e.toString() == value,
      orElse: () => ValidationStatus.pending,
    );
  }
  
  String get displayName {
    switch (this) {
      case ValidationStatus.pending:
        return 'Pending';
      case ValidationStatus.processing:
        return 'Processing';
      case ValidationStatus.completed:
        return 'Completed';
      case ValidationStatus.failed:
        return 'Failed';
    }
  }
  
  Color get color {
    switch (this) {
      case ValidationStatus.pending:
        return Colors.orange;
      case ValidationStatus.processing:
        return Colors.blue;
      case ValidationStatus.completed:
        return Colors.green;
      case ValidationStatus.failed:
        return Colors.red;
    }
  }
  
  IconData get icon {
    switch (this) {
      case ValidationStatus.pending:
        return Icons.pending;
      case ValidationStatus.processing:
        return Icons.refresh;
      case ValidationStatus.completed:
        return Icons.check_circle;
      case ValidationStatus.failed:
        return Icons.error;
    }
  }
}
