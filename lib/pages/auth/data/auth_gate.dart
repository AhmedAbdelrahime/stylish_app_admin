import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/core/services/supabase_client.dart';
import 'package:hungry/pages/auth/data/auth_service.dart';
import 'package:hungry/pages/auth/screens/access_denied_screen.dart';
import 'package:hungry/pages/auth/screens/login_screen.dart';
import 'package:hungry/root.dart';
import 'package:hungry/shared/custom_text.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveDestination());
  }

  Future<void> _resolveDestination() async {
    final session = appSupabase.auth.currentSession;

    if (session == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    try {
      final isAdmin = await _authService.validateCurrentSessionIsAdmin();

      if (!mounted) return;

      if (isAdmin) {
        _navigateTo(const Root());
        return;
      }

      _navigateTo(const AccessDeniedScreen());
    } catch (_) {
      await _authService.signOut();
      if (!mounted) return;
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget page) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.redColor),
            SizedBox(height: 18),
            CustomText(
              text: 'Checking access...',
              size: 18,
              weight: FontWeight.w600,
              color: AppColors.blackColor,
            ),
          ],
        ),
      ),
    );
  }
}
