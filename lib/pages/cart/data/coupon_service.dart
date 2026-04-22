import 'package:supabase_flutter/supabase_flutter.dart';

class AppliedCoupon {
  const AppliedCoupon({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.usedCount,
    this.description,
  });

  final String id;
  final String code;
  final String? description;
  final double discountAmount;
  final int usedCount;
}

class CouponService {
  CouponService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<AppliedCoupon> validateCoupon({
    required String code,
    required double subtotal,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw Exception('Enter a coupon code first');
    }

    final data = await _supabase
        .from('coupons')
        .select()
        .ilike('code', normalizedCode)
        .maybeSingle();

    if (data == null) {
      throw Exception('Coupon code not found');
    }

    final isActive = data['is_active'] == true;
    if (!isActive) {
      throw Exception('This coupon is not active');
    }

    final now = DateTime.now().toUtc();
    final startsAt = _parseDateTime(data['starts_at']);
    final expiresAt = _parseDateTime(data['expires_at']);

    if (startsAt != null && now.isBefore(startsAt)) {
      throw Exception('This coupon is not active yet');
    }

    if (expiresAt != null && now.isAfter(expiresAt)) {
      throw Exception('This coupon has expired');
    }

    final usageLimit = data['usage_limit'] as int?;
    final usedCount = (data['used_count'] as num?)?.toInt() ?? 0;
    if (usageLimit != null && usedCount >= usageLimit) {
      throw Exception('This coupon has reached its usage limit');
    }

    final minOrderAmount = (data['min_order_amount'] as num?)?.toDouble() ?? 0;
    if (subtotal < minOrderAmount) {
      throw Exception(
        'Coupon requires a minimum order of ₹${_formatAmount(minOrderAmount)}',
      );
    }

    final discountType = (data['discount_type'] ?? 'percent').toString();
    final discountValue = (data['discount_value'] as num?)?.toDouble() ?? 0;
    final maxDiscountAmount = (data['max_discount_amount'] as num?)?.toDouble();

    double discountAmount;
    if (discountType == 'fixed') {
      discountAmount = discountValue;
    } else {
      discountAmount = subtotal * (discountValue / 100);
      if (maxDiscountAmount != null && discountAmount > maxDiscountAmount) {
        discountAmount = maxDiscountAmount;
      }
    }

    discountAmount = discountAmount.clamp(0, subtotal);

    return AppliedCoupon(
      id: data['id'] as String,
      code: (data['code'] as String).toUpperCase(),
      description: data['description'] as String?,
      discountAmount: discountAmount,
      usedCount: usedCount,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }
}
