class AdminBannerModel {
  const AdminBannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    required this.targetType,
    this.targetValue,
    required this.isActive,
    required this.sortOrder,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String targetType;
  final String? targetValue;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;

  factory AdminBannerModel.fromJson(Map<String, dynamic> json) {
    return AdminBannerModel(
      id: json['id'].toString(),
      title: (json['title'] ?? '') as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: (json['image_url'] ?? '') as String,
      targetType: (json['target_type'] ?? 'url') as String,
      targetValue: json['target_value'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
