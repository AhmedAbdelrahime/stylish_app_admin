import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/pages/auth/data/auth_service.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/product/widgets/product_app_bar.dart';
import 'package:hungry/pages/settings/widgets/logout_dialog.dart';

class AppBarSection extends StatefulWidget implements PreferredSizeWidget {
  const AppBarSection({super.key});

  @override
  State<AppBarSection> createState() => _AppBarSectionState();

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarSectionState extends State<AppBarSection> {
  bool isloading = false;
  final _authService = AuthService();

  Future<void> supabaseLogout() async {
    try {
      setState(() => isloading = true);
      await _authService.signOut();
      setState(() => isloading = false);
    } catch (e) {
      final readableMessage = SupabaseErrorMapper.map(e);
      if (!mounted) return;

      AppSnackBar.show(
        context: context,
        text: readableMessage,
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => isloading = false);
    }
  }

  Future<void> showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LogoutDialog(),
    );

    if (shouldLogout == true) {
      await supabaseLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return ProductAppBar(
      text: 'Settings',
      padiing: 20,
      showbackicon: canGoBack,
      isSettingpage: true,
      logout: showLogoutDialog,
    );
  }
}
