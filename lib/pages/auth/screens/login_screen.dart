import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/auth/data/auth_gate.dart';
import 'package:hungry/pages/auth/data/auth_service.dart';
import 'package:hungry/pages/auth/screens/access_denied_screen.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/auth/widgets/login_form.dart';
import 'package:hungry/shared/custom_button.dart';
import 'package:hungry/shared/custom_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailControler = TextEditingController();
  TextEditingController passControler = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isloading = false;
  final _authService = AuthService();
  @override
  void dispose() {
    emailControler.dispose();
    passControler.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isloading = true);

    try {
      await _authService.signIn(
        email: emailControler.text.trim(),
        password: passControler.text.trim(),
      );
      // login success

      if (!mounted) return;

      AppSnackBar.show(
        context: context,
        text: 'Login successful',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    } catch (e) {
      if (e.toString().contains(AuthService.adminAccessDeniedMessage)) {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AccessDeniedScreen()),
        );
        return;
      }

      final readableMessage = SupabaseErrorMapper.map(e);

      AppSnackBar.show(
        context: context,
        text: readableMessage,
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isloading = false);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(text: 'Welcome', size: 30, weight: FontWeight.bold),
              CustomText(text: 'Back!', size: 30, weight: FontWeight.bold),
              Gap(20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    LoginForm(
                      emailControler: emailControler,
                      passControler: passControler,
                    ),
                    Gap(30),
                    _isloading
                        ? CupertinoActivityIndicator(
                            color: AppColors.redColor,
                            radius: 20,
                          )
                        : CustomButton(ontap: _logIn, text: "Login"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
