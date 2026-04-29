import 'package:hungry/pages/admin/data/admin_banner_model.dart';
import 'package:hungry/pages/admin/data/admin_coupon_model.dart';
import 'package:hungry/pages/admin/data/admin_offer_model.dart';
import 'package:hungry/pages/admin/data/admin_audit_service.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class AdminPromotionService {
  AdminPromotionService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  static const _promotionBuckets = [
    'promotions',
    'banners',
    'offers',
    'categories',
  ];

  Future<List<AdminCouponModel>> getCoupons() async {
    final data = await _supabase
        .from('coupons')
        .select()
        .order('created_at', ascending: false);
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AdminCouponModel.fromJson)
        .toList();
  }

  Future<List<AdminCouponModel>> getDashboardCoupons() async {
    final data = await _supabase
        .from('coupons')
        .select('id, code, is_active, expires_at')
        .order('created_at', ascending: false);
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AdminCouponModel.fromJson)
        .toList();
  }

  Future<List<AdminBannerModel>> getBanners() async {
    final data = await _supabase
        .from('banners')
        .select()
        .order('sort_order')
        .order('created_at', ascending: false);
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AdminBannerModel.fromJson)
        .toList();
  }

  Future<List<AdminBannerModel>> getDashboardBanners() async {
    final data = await _supabase
        .from('banners')
        .select('id, title, is_active')
        .order('sort_order')
        .order('created_at', ascending: false);
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AdminBannerModel.fromJson)
        .toList();
  }

  Future<List<AdminOfferModel>> getOffers() async {
    final data = await _supabase
        .from('offers')
        .select()
        .order('created_at', ascending: false);
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AdminOfferModel.fromJson)
        .toList();
  }

  Future<List<AdminOfferModel>> getDashboardOffers() async {
    final data = await _supabase
        .from('offers')
        .select('id')
        .order('created_at', ascending: false);
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AdminOfferModel.fromJson)
        .toList();
  }

  Future<void> createCoupon({
    required String code,
    String? description,
    required String discountType,
    required double discountValue,
    required double minOrderAmount,
    double? maxDiscountAmount,
    int? usageLimit,
    required bool isActive,
    DateTime? startsAt,
    DateTime? expiresAt,
  }) async {
    final payload = {
      'code': code.trim().toUpperCase(),
      'description': _normalize(description),
      'discount_type': discountType.trim(),
      'discount_value': discountValue,
      'min_order_amount': minOrderAmount,
      'max_discount_amount': maxDiscountAmount,
      'usage_limit': usageLimit,
      'is_active': isActive,
      'starts_at': startsAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
    await _supabase.from('coupons').insert(payload);
    await _logAuditEvent(
      action: 'create_coupon',
      entityType: 'coupon',
      details: payload,
    );
  }

  Future<void> updateCoupon({
    required String id,
    required String code,
    String? description,
    required String discountType,
    required double discountValue,
    required double minOrderAmount,
    double? maxDiscountAmount,
    int? usageLimit,
    required bool isActive,
    DateTime? startsAt,
    DateTime? expiresAt,
  }) async {
    final payload = {
      'code': code.trim().toUpperCase(),
      'description': _normalize(description),
      'discount_type': discountType.trim(),
      'discount_value': discountValue,
      'min_order_amount': minOrderAmount,
      'max_discount_amount': maxDiscountAmount,
      'usage_limit': usageLimit,
      'is_active': isActive,
      'starts_at': startsAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
    await _supabase.from('coupons').update(payload).eq('id', id);
    await _logAuditEvent(
      action: 'update_coupon',
      entityType: 'coupon',
      entityId: id,
      details: payload,
    );
  }

  Future<void> deleteCoupon(String id) async {
    await _supabase.from('coupons').delete().eq('id', id);
    await _logAuditEvent(
      action: 'delete_coupon',
      entityType: 'coupon',
      entityId: id,
      details: {'id': id},
    );
  }

  Future<void> updateCouponActiveState({
    required String id,
    required bool isActive,
  }) async {
    await _supabase
        .from('coupons')
        .update({'is_active': isActive})
        .eq('id', id);
    await _logAuditEvent(
      action: 'toggle_coupon_active',
      entityType: 'coupon',
      entityId: id,
      details: {'is_active': isActive},
    );
  }

  Future<void> createBanner({
    required String title,
    String? subtitle,
    required String imageUrl,
    required String targetType,
    String? targetValue,
    required bool isActive,
    required int sortOrder,
  }) async {
    final payload = {
      'title': title.trim(),
      'subtitle': _normalize(subtitle),
      'image_url': imageUrl.trim(),
      'target_type': targetType.trim(),
      'target_value': _normalize(targetValue),
      'is_active': isActive,
      'sort_order': sortOrder,
    };
    await _supabase.from('banners').insert(payload);
    await _logAuditEvent(
      action: 'create_banner',
      entityType: 'banner',
      details: payload,
    );
  }

  Future<void> createOffer({required String imageUrl, String? title}) async {
    final payload = {'image_url': imageUrl.trim(), 'title': _normalize(title)};
    await _supabase.from('offers').insert(payload);
    await _logAuditEvent(
      action: 'create_offer',
      entityType: 'offer',
      details: payload,
    );
  }

  Future<void> updateOffer({
    required String id,
    required String imageUrl,
    String? title,
  }) async {
    final payload = {'image_url': imageUrl.trim(), 'title': _normalize(title)};
    await _supabase.from('offers').update(payload).eq('id', id);
    await _logAuditEvent(
      action: 'update_offer',
      entityType: 'offer',
      entityId: id,
      details: payload,
    );
  }

  Future<void> deleteOffer(String id) async {
    await _supabase.from('offers').delete().eq('id', id);
    await _logAuditEvent(
      action: 'delete_offer',
      entityType: 'offer',
      entityId: id,
      details: {'id': id},
    );
  }

  Future<void> updateBanner({
    required String id,
    required String title,
    String? subtitle,
    required String imageUrl,
    required String targetType,
    String? targetValue,
    required bool isActive,
    required int sortOrder,
  }) async {
    final payload = {
      'title': title.trim(),
      'subtitle': _normalize(subtitle),
      'image_url': imageUrl.trim(),
      'target_type': targetType.trim(),
      'target_value': _normalize(targetValue),
      'is_active': isActive,
      'sort_order': sortOrder,
    };
    await _supabase.from('banners').update(payload).eq('id', id);
    await _logAuditEvent(
      action: 'update_banner',
      entityType: 'banner',
      entityId: id,
      details: payload,
    );
  }

  Future<void> deleteBanner(String id) async {
    await _supabase.from('banners').delete().eq('id', id);
    await _logAuditEvent(
      action: 'delete_banner',
      entityType: 'banner',
      entityId: id,
      details: {'id': id},
    );
  }

  Future<void> reorderBanners(List<AdminBannerModel> banners) async {
    for (var index = 0; index < banners.length; index++) {
      await _supabase
          .from('banners')
          .update({'sort_order': index})
          .eq('id', banners[index].id);
    }
    await _logAuditEvent(
      action: 'reorder_banners',
      entityType: 'banner',
      details: {
        'order': [
          for (var index = 0; index < banners.length; index++)
            {'id': banners[index].id, 'sort_order': index},
        ],
      },
    );
  }

  Future<String> uploadPromotionImageBytes({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    String folder = 'promotions',
  }) async {
    final extension = path.extension(fileName).toLowerCase();
    final safeExtension = extension.isEmpty ? '.png' : extension;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final storagePath = '$folder/media_$timestamp$safeExtension';
    final contentType = _resolveContentType(
      fileName: fileName,
      mimeType: mimeType,
    );

    Object? lastError;
    for (final bucket in _promotionBuckets) {
      try {
        await _supabase.storage
            .from(bucket)
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: FileOptions(upsert: true, contentType: contentType),
            );
        return _supabase.storage.from(bucket).getPublicUrl(storagePath);
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? 'Could not upload promotion image.';
  }

  String _resolveContentType({required String fileName, String? mimeType}) {
    if (mimeType != null && mimeType.trim().isNotEmpty) {
      return mimeType;
    }

    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.png':
      default:
        return 'image/png';
    }
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
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
      // Ignore audit logging failures to avoid blocking main admin actions.
    }
  }
}
