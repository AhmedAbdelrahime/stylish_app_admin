import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/core/services/supabase_client.dart';
import 'package:hungry/pages/admin/screens/admin_category_screen.dart';
import 'package:hungry/pages/admin/screens/admin_audit_screen.dart';
import 'package:hungry/pages/admin/screens/admin_dashboard_screen.dart';
import 'package:hungry/pages/admin/screens/admin_order_screen.dart';
import 'package:hungry/pages/admin/screens/admin_promotion_screen.dart';
import 'package:hungry/pages/admin/screens/admin_product_screen.dart';
import 'package:hungry/pages/admin/screens/admin_user_screen.dart';
import 'package:hungry/pages/auth/data/auth_service.dart';
import 'package:hungry/pages/auth/screens/login_screen.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  late final StreamSubscription<AuthState> _authSubscription;
  final AuthService _authService = AuthService();

  final List<_AdminSection> _sections = const [
    _AdminSection(
      label: 'Dashboard',
      subtitle: 'Track the store, review metrics, and manage daily activity.',
      icon: Icons.space_dashboard_outlined,
      page: AdminDashboardScreen(),
    ),
    _AdminSection(
      label: 'Categories',
      subtitle:
          'Create, edit, and connect categories with the products they organize.',
      icon: Icons.category_outlined,
      page: AdminCategoryScreen(),
    ),
    _AdminSection(
      label: 'Products',
      subtitle:
          'Create, edit, search, and organize the catalog with inventory and status controls.',
      icon: Icons.inventory_2_outlined,
      page: AdminProductScreen(),
    ),
    _AdminSection(
      label: 'Orders',
      subtitle:
          'Review incoming orders, update payment and delivery states, and inspect user details.',
      icon: Icons.receipt_long_outlined,
      page: AdminOrderScreen(),
    ),
    _AdminSection(
      label: 'Users',
      subtitle:
          'Search user accounts, update profile details, and manage admin access cleanly.',
      icon: Icons.people_alt_outlined,
      page: AdminUserScreen(),
    ),
    _AdminSection(
      label: 'Audit',
      subtitle:
          'Inspect admin activity, trace entity changes, and review structured log details.',
      icon: Icons.history_edu_outlined,
      page: AdminAuditScreen(),
    ),
    _AdminSection(
      label: 'Promotions',
      subtitle:
          'Manage coupon campaigns and storefront banners from one admin workspace.',
      icon: Icons.campaign_outlined,
      page: AdminPromotionScreen(),
    ),
  ];

  int _currentPage = 0;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = appSupabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null || !mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  Future<void> _logOut() async {
    try {
      setState(() => _isLoggingOut = true);
      await _authService.signOut();
    } catch (error) {
      if (!mounted) return;

      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSection = _sections[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF3F4F8),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1380),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                          color: Colors.black.withValues(alpha: 0.05),
                        ),
                      ],
                    ),
                    child: Wrap(
                      runSpacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.redColor,
                                    Color(0xFFFF6A4D),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stylish Admin',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.blackColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Desktop-first control panel for your store',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...List.generate(_sections.length, (index) {
                              final section = _sections[index];
                              final isSelected = index == _currentPage;

                              return InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () {
                                  setState(() => _currentPage = index);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.blackColor
                                        : AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        section.icon,
                                        size: 18,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.hintColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        section.label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.blackColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            _isLoggingOut
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.redColor,
                                    ),
                                  )
                                : FilledButton.icon(
                                    onPressed: _logOut,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.redColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(Icons.logout_outlined),
                                    label: const Text(
                                      'Logout',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1380),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedSection.label,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.blackColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selectedSection.subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.hintColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: IndexedStack(
                            index: _currentPage,
                            children: _sections
                                .map((section) => section.page)
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSection {
  const _AdminSection({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.page,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Widget page;
}
