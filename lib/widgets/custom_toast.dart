import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

class CustomToast extends StatelessWidget {
  final String message;
  final ToastType type;
  final VoidCallback? onClose;

  const CustomToast({
    Key? key,
    required this.message,
    required this.type,
    this.onClose,
  }) : super(key: key);

  Color get _backgroundColor {
    switch (type) {
      case ToastType.success:
        return const Color(0xFFE6F4EA);
      case ToastType.error:
        return const Color(0xFFFDEAEA);
      case ToastType.warning:
        return const Color(0xFFFFF8E1);
      case ToastType.info:
        return const Color(0xFFE3F2FD);
    }
  }

  Color get _iconColor {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF34A853);
      case ToastType.error:
        return const Color(0xFFEA4335);
      case ToastType.warning:
        return const Color(0xFFF9AB00);
      case ToastType.info:
        return const Color(0xFF4285F4);
    }
  }

  IconData get _iconData {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
    }
  }

  String get _label {
    switch (type) {
      case ToastType.success:
        return 'Success';
      case ToastType.error:
        return 'Error';
      case ToastType.warning:
        return 'Warning';
      case ToastType.info:
        return 'Info';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_iconData, color: _iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: _iconColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(Icons.close, size: 18),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
        ],
      ),
    );
  }
} 