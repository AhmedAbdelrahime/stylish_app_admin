import 'package:hungry/pages/settings/data/user_model.dart';

class AdminAuditLogModel {
  const AdminAuditLogModel({
    required this.id,
    this.adminUserId,
    required this.action,
    required this.entityType,
    this.entityId,
    required this.details,
    required this.createdAt,
    this.adminUser,
  });

  final String id;
  final String? adminUserId;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final UserModel? adminUser;

  String get actorLabel {
    if (adminUser == null) return 'Unknown admin';
    return adminUser!.displayName;
  }

  String get actorEmail => adminUser?.email ?? 'No email';

  String get actionLabel => action.replaceAll('_', ' ');

  factory AdminAuditLogModel.fromJson(Map<String, dynamic> json) {
    final detailsValue = json['details'];
    final actorValue = json['admin_profile'];

    return AdminAuditLogModel(
      id: json['id'].toString(),
      adminUserId: json['admin_user_id']?.toString(),
      action: (json['action'] ?? '') as String,
      entityType: (json['entity_type'] ?? '') as String,
      entityId: json['entity_id']?.toString(),
      details: detailsValue is Map<String, dynamic> ? detailsValue : const {},
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      adminUser: actorValue is Map<String, dynamic>
          ? UserModel.fromJson(actorValue)
          : null,
    );
  }
}
