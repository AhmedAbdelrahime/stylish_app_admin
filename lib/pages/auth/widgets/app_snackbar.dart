import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/shared/custom_text.dart';

class AppSnackBar {
  static void show({
    required BuildContext context,
    required String text,
    IconData icon = Icons.info_outline,
    Color backgroundColor = Colors.black87,
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
    double borderRadius = 5,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor),
              Gap(5),
              CustomText(
                text: text,
                size: 14,
                weight: FontWeight.w400,
                color: textColor,
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(12),
          clipBehavior: Clip.none,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      );
  }
}
