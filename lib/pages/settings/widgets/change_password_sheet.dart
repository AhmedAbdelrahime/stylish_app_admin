import 'package:flutter/cupertino.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/auth/widgets/reset_password_form.dart';
import 'package:hungry/pages/cart/widgets/cart_btn.dart';

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({
    super.key,
    required this.formKey,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final Future<void> Function() onSubmit;

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  bool isChangePassLoading = false;
  Future<void> _handelsubmit() async {
    if (!widget.formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isChangePassLoading = true;
    });
    await widget.onSubmit();
    if (mounted) {
      isChangePassLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResetPasswordForm(
              formKey: widget.formKey,
              passControler: widget.newPasswordController,
              confirmControler: widget.confirmPasswordController,
            ),
            const Gap(20),
            isChangePassLoading
                ? const CupertinoActivityIndicator(
                    radius: 18,
                    color: AppColors.redColor,
                  )
                : CartBtn(ontap: _handelsubmit, text: 'Change Password'),
          ],
        ),
      ),
    );
  }
}
