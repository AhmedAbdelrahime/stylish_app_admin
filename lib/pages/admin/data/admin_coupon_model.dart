class AdminCouponModel {
  const AdminCouponModel({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    this.maxDiscountAmount,
    this.usageLimit,
    required this.usedCount,
    required this.isActive,
    this.startsAt,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final int? usageLimit;
  final int usedCount;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory AdminCouponModel.fromJson(Map<String, dynamic> json) {
    return AdminCouponModel(
      id: json['id'].toString(),
      code: (json['code'] ?? '') as String,
      description: json['description'] as String?,
      discountType: (json['discount_type'] ?? 'percent') as String,
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
      usageLimit: (json['usage_limit'] as num?)?.toInt(),
      usedCount: (json['used_count'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
