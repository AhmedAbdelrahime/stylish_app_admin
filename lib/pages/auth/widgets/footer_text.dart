import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/shared/custom_text.dart';

class FoooterText extends StatelessWidget {
  const FoooterText({
    super.key,
    required this.text1,
    required this.text2,
    this.onTap,
  });
  final String text1;
  final String text2;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomText(
          text: text1,
          size: 14,
          weight: FontWeight.w400,
          color: AppColors.hintColor,
        ),
        Gap(5),
        GestureDetector(
          onTap: onTap,
          child: CustomText(
            text: text2,
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.redColor,
          ),
        ),
      ],
    );
  }
}
