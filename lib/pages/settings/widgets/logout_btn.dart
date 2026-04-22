import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/shared/custom_text.dart';

class LogoutBtn extends StatelessWidget {
  const LogoutBtn({super.key, this.onTap});
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.redColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              text: 'Logout ',
              color: AppColors.primaryColor,
              weight: FontWeight.w600,
              size: 18,
            ),
            Icon(
              Icons.logout_outlined,
              color: AppColors.primaryColor,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}
