import 'package:flutter/foundation.dart';
import 'package:hungry/core/services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const String adminAccessDeniedMessage =
      'Access denied. Only admin accounts can log in.';

  final SupabaseClient _supabase = appSupabase;

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final user = response.user;

      if (kDebugMode) {
        debugPrint('User created: $user');
      }

      if (user != null) {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'full_name': fullName,
        });

        if (kDebugMode) {
          debugPrint(user.toString());
        }
      }
    } catch (error) {
      throw error.toString();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final isAdmin = await _isCurrentUserAdmin(userId: response.user?.id);

      if (!isAdmin) {
        await _supabase.auth.signOut();
        throw adminAccessDeniedMessage;
      }

      if (kDebugMode) {
        debugPrint('User Login: ${response.user}');
      }
    } catch (error) {
      throw error.toString();
    }
  }

  Future<bool> validateCurrentSessionIsAdmin() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return false;

    final isAdmin = await _isCurrentUserAdmin(userId: user.id);

    if (!isAdmin) {
      await _supabase.auth.signOut();
    }

    return isAdmin;
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      if (kDebugMode) {
        debugPrint('User signed out');
      }
    } catch (error) {
      throw error.toString();
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        throw 'No account found with this email';
      }

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.hungry://reset-password',
      );

      if (kDebugMode) {
        debugPrint('Reset password email sent');
      }
    } catch (error) {
      throw error.toString();
    }
  }

  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      if (kDebugMode) {
        debugPrint('Password updated successfully');
      }
    } catch (error) {
      throw error.toString();
    }
  }

  Future<void> changePassword(String newPassword) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw 'User not logged in';
    }

    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<bool> _isCurrentUserAdmin({String? userId}) async {
    final resolvedUserId = userId ?? _supabase.auth.currentUser?.id;

    if (resolvedUserId == null) return false;

    final data = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', resolvedUserId)
        .maybeSingle();

    final role = data?['role'];

    return role is String && role.trim().toLowerCase() == 'admin';
  }
}
