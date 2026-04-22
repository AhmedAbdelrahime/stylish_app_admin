import 'package:hungry/pages/admin/data/admin_audit_log_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAuditService {
  AdminAuditService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<List<AdminAuditLogModel>> getAuditLogs() async {
    final data = await _supabase
        .from('admin_audit_logs')
        .select(
          '''
          *,
          admin_profile:profiles!admin_audit_logs_admin_user_id_fkey(
            id,
            full_name,
            email,
            image,
            address,
            city,
            state,
            country,
            pincode,
            role
          )
          ''',
        )
        .order('created_at', ascending: false);

    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AdminAuditLogModel.fromJson)
        .toList();
  }
}
