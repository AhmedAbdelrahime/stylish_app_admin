import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/auth/widgets/custom_auth_textfiled.dart';
import 'package:hungry/shared/custom_text.dart';

class SinagupForm extends StatelessWidget {
  const SinagupForm({
    super.key,
    required this.nameControler,
    required this.emailControler,
    required this.passControler,
    required this.confirmControler,
  });
  final TextEditingController nameControler;
  final TextEditingController emailControler;
  final TextEditingController passControler;
  final TextEditingController confirmControler;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomAuthTextfiled(
          keyboardType: TextInputType.name,
          controller: nameControler,
          labelText: 'Full Name',
          icone: Icons.badge_outlined,
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Please enter your full name';
            }
            if (trimmed.length < 2) {
              return 'Full name must be at least 2 characters';
            }
            if (trimmed.length > 50) {
              return 'Full name cannot be more than 50 characters';
            }
            return null;
          },
        ),
        Gap(15),
        CustomAuthTextfiled(
          keyboardType: TextInputType.emailAddress,
          controller: emailControler,
          labelText: 'Email',
          icone: Icons.email_outlined,
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Please enter your email';
            }
            if (!trimmed.contains('@') || !trimmed.contains('.')) {
              return 'Please enter a valid email address';
            }
            if (trimmed.length > 100) {
              return 'Email cannot be more than 100 characters';
            }
            return null;
          },
        ),
        const Gap(15),
        CustomAuthTextfiled(
          keyboardType: TextInputType.visiblePassword,
          controller: passControler,
          labelText: 'Password',
          icone: Icons.lock,
          isPassowed: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            if (value.length > 20) {
              return 'Password cannot be more than 20 characters';
            }
            return null;
          },
        ),
        const Gap(15),
        CustomAuthTextfiled(
          keyboardType: TextInputType.visiblePassword,
          controller: confirmControler,
          labelText: 'Confirm Password',
          icone: Icons.lock,
          isPassowed: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != passControler.text) {
              return 'Passwords do not match';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            if (value.length > 20) {
              return 'Password cannot be more than 20 characters';
            }
            return null;
          },
        ),
        const Gap(10),

        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CustomText(
              text:
                  'By creating an account, you agree to the app terms and privacy policy.',
              size: 13,
              weight: FontWeight.w400,
              color: AppColors.grayColor,
            ),
          ),
        ),
      ],
    );
  }
}
