import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/pages/auth/widgets/custom_auth_textfiled.dart';

class ResetPasswordForm extends StatelessWidget {
  const ResetPasswordForm({
    super.key,
    required this.passControler,
    required this.confirmControler,
    required this.formKey,
  });
  final TextEditingController passControler;
  final TextEditingController confirmControler;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          CustomAuthTextfiled(
            keyboardType: TextInputType.visiblePassword,
            controller: passControler,
            labelText: 'Enter New Password',
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
          Gap(15),
          CustomAuthTextfiled(
            keyboardType: TextInputType.visiblePassword,
            controller: confirmControler,
            labelText: ' Confirm Password',
            icone: Icons.lock,
            isPassowed: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value != passControler.text) {
                return 'Password must Machted ';
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
          Gap(10),
        ],
      ),
    );
  }
}
