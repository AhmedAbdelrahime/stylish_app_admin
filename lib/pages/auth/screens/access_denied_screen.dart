import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/auth/screens/login_screen.dart';
import 'package:hungry/shared/custom_button.dart';
import 'package:hungry/shared/custom_text.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                    color: AppColors.blackColor.withValues(alpha: 0.08),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 82,
                    width: 82,
                    decoration: BoxDecoration(
                      color: AppColors.redColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.redColor,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CustomText(
                    text: 'Access Denied',
                    size: 28,
                    weight: FontWeight.w700,
                    color: AppColors.blackColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This panel is available only for admin accounts. Please try again with an authorized admin email and password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.hintColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Try Login Again',
                    ontap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
