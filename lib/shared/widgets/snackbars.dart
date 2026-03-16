import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Shows a green auto-dismissing snackbar (3 seconds).
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: primaryGreen,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Shows a red snackbar (manual dismiss).
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: errorRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white70,
        onPressed: () =>
            ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    ),
  );
}
