import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:hungry/pages/admin/data/admin_audit_service.dart';
import 'package:hungry/pages/settings/data/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<UserModel>> getAllProfiles() async {
    final data = await _supabase
        .from('profiles')
        .select()
        .order('full_name')
        .order('email');

    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  Future<List<UserModel>> getDashboardProfiles() async {
    final data = await _supabase
        .from('profiles')
        .select('id, email, role')
        .order('email');

    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  Future<UserModel?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _ensureProfileExists();

    if (data == null) {
      final metadata = user.userMetadata ?? <String, dynamic>{};

      return UserModel(
        userId: user.id,
        email: user.email ?? '',
        name: metadata['full_name']?.toString(),
        image: metadata['image']?.toString(),
      );
    }

    return UserModel.fromJson(data);
  }

  Future<void> updateProfile(UserModel user) async {
    await _ensureProfileExists();
    await _supabase.from('profiles').upsert({
      'id': user.userId,
      'email': user.email,
      ...user.toJson(),
    });
    await _logAuditEvent(
      action: 'update_profile',
      entityType: 'profile',
      entityId: user.userId,
      details: {'email': user.email, ...user.toJson()},
    );
  }

  Future<void> adminUpdateProfile(UserModel user) async {
    final payload = {'email': user.email, ...user.toJson(), 'role': user.role};
    await _supabase.from('profiles').update(payload).eq('id', user.userId);
    await _logAuditEvent(
      action: 'admin_update_profile',
      entityType: 'user',
      entityId: user.userId,
      details: payload,
    );
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await _supabase
        .from('profiles')
        .update({'role': role.trim().toLowerCase()})
        .eq('id', userId);
    await _logAuditEvent(
      action: 'update_user_role',
      entityType: 'user',
      entityId: userId,
      details: {'role': role.trim().toLowerCase()},
    );
  }

  Future<bool> isCurrentUserAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final data = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return false;

    final role = data['role'];
    return role is String && role.trim().toLowerCase() == 'admin';
  }

  Future<void> updateProfileImage({
    required String userId,
    required String imageUrl,
  }) async {
    await _supabase
        .from('profiles')
        .update({'image': imageUrl})
        .eq('id', userId);
    await _logAuditEvent(
      action: 'update_profile_image',
      entityType: 'profile',
      entityId: userId,
      details: {'image': imageUrl},
    );
  }

  Future<String> uploadProfileImage(File file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final fileExt = path.extension(file.path);
    final fileName = '${user.id}$fileExt';
    final filePath = 'avatars/$fileName';

    await _supabase.storage
        .from('avatars')
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

    return imageUrl;
  }

  Future<Map<String, dynamic>?> _ensureProfileExists() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final existing = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) {
      return existing;
    }

    final metadata = user.userMetadata ?? <String, dynamic>{};
    final payload = <String, dynamic>{
      'id': user.id,
      'email': user.email,
      'full_name': metadata['full_name']?.toString(),
      'image': metadata['image']?.toString(),
    };

    await _supabase.from('profiles').upsert(payload);

    return _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
  }

  Future<void> _logAuditEvent({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await AdminAuditService(supabase: _supabase).logEvent(
        action: action,
        entityType: entityType,
        entityId: entityId,
        details: details,
      );
    } catch (_) {
      // Keep profile flows working even if audit insert fails.
    }
  }
}
