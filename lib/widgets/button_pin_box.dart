import 'package:flutter/material.dart';
import 'package:kindmap/config/app_theme.dart';

Widget PinBoxButton({
  required BuildContext context,
  required String label,
  required Color bgColor,
  required Color textColor,
  required VoidCallback onPressed,
  FontWeight weight = FontWeight.w600,
  double letterSpacing = 0,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.pressed)) {
            return bgColor.withOpacity(0.9); // Pressed effect
          }
          return bgColor;
        }),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: KMTheme.of(context).titleMedium.copyWith(
              fontWeight: weight,
              letterSpacing: letterSpacing,
              color: textColor,
            ),
      ),
    ),
  );
}
