import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/shared/custom_text.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({super.key, required this.ontap, required this.text});
  final VoidCallback ontap;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.redColor,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
          child: CustomText(
            text: text,
            size: 24,
            weight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}
