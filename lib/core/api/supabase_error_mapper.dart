import 'package:flutter/foundation.dart';

class SupabaseErrorMapper {
  static String map(dynamic error) {
    final message = error.toString();

    if (message.contains('Invalid login credentials')) {
      return 'Email or password is incorrect';
    }

    if (message.contains('Email not confirmed')) {
      return 'Please verify your email before logging in';
    }

    if (message.contains('Only admin accounts can log in')) {
      return 'Access denied. Only admin accounts can log in.';
    }

    if (message.contains('User already registered')) {
      return 'This email is already registered';
    }

    if (message.contains('Password should be at least')) {
      return 'Password is too weak';
    }

    if (message.contains('Signup is disabled')) {
      return 'Account creation is currently disabled';
    }

    if (message.contains('No account found with this email')) {
      return 'No account found with this email';
    }

    if (message.contains(
      'New password should be different from the old password',
    )) {
      return 'New password should be different from the old password';
    }

    if (message.contains('JWT expired')) {
      return 'Session expired. Please login again';
    }

    if (message.contains('duplicate key') ||
        message.contains('This record already exists')) {
      return 'This record already exists';
    }

    if (message.contains('violates row-level security')) {
      return 'You are not allowed to perform this action';
    }

    if (message.contains('null value')) {
      return 'Required information is missing';
    }

    if (message.contains('ClientException with SocketException')) {
      return 'No internet connection.';
    }

    if (message.contains('Failed host lookup') ||
        message.contains('Connection timed out') ||
        message.contains('Network is unreachable')) {
      return 'Unable to connect to server. Please try again later.';
    }

    if (message.contains('User not logged in')) {
      return 'User not logged in';
    }

    if (message.contains('storage/object-not-found')) {
      return 'The uploaded file could not be found in storage.';
    }

    if (message.contains('storage') &&
        (message.contains('403') || message.contains('401'))) {
      return 'Storage access was denied. Please check Supabase bucket policies.';
    }

    if (kDebugMode) {
      debugPrint('[SupabaseErrorMapper] raw=$message');
    }

    return message.isNotEmpty
        ? message
        : 'Something went wrong. Please try again.';
  }
}
