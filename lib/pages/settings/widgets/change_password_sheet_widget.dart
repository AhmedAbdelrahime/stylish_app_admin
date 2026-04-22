import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/core/utils/bottom_sheet_helper.dart';
import 'package:hungry/pages/auth/data/auth_service.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/settings/widgets/change_password_sheet.dart';
import 'package:hungry/shared/custom_text.dart';

class ChangePasswordSheetWidget extends StatefulWidget {
  const ChangePasswordSheetWidget({super.key});

  @override
  State<ChangePasswordSheetWidget> createState() =>
      _ChangePasswordSheetWidgetState();
}

class _ChangePasswordSheetWidgetState extends State<ChangePasswordSheetWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _authService = AuthService();

  Future<void> handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _authService.changePassword(newPasswordController.text.trim());

      if (!mounted) return;
      Navigator.of(context).pop();

      AppSnackBar.show(
        context: context,
        text: 'Password updateded Please login again.',
        backgroundColor: Colors.green,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // Security best practice
      await _authService.signOut();
    } catch (e) {
      if (!mounted) return;
      final message = SupabaseErrorMapper.map(e.toString());

      debugPrint('handleChangePassword: $message');
      Navigator.of(context).pop();
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      AppSnackBar.show(
        context: context,
        text: message,
        backgroundColor: Colors.red,
      );
    }
  }

  void openChangePasswordSheet() {
    BottomSheetHelper.show(
      context: context,
      child: ChangePasswordSheet(
        formKey: _formKey,
        newPasswordController: newPasswordController,
        confirmPasswordController: confirmPasswordController,
        onSubmit: handleChangePassword,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: openChangePasswordSheet,
        child: CustomText(
          text: 'Change Password',
          size: 16,
          weight: FontWeight.w600,
          color: AppColors.redColor,
        ),
      ),
    );
  }
}
