import 'package:hungry/pages/admin/data/admin_banner_model.dart';
import 'package:hungry/pages/admin/data/admin_coupon_model.dart';
import 'package:hungry/pages/admin/data/admin_offer_model.dart';
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
    await _supabase.from('coupons').insert({
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
    });
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
    await _supabase.from('coupons').update({
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
    }).eq('id', id);
  }

  Future<void> deleteCoupon(String id) async {
    await _supabase.from('coupons').delete().eq('id', id);
  }

  Future<void> updateCouponActiveState({
    required String id,
    required bool isActive,
  }) async {
    await _supabase
        .from('coupons')
        .update({'is_active': isActive})
        .eq('id', id);
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
    await _supabase.from('banners').insert({
      'title': title.trim(),
      'subtitle': _normalize(subtitle),
      'image_url': imageUrl.trim(),
      'target_type': targetType.trim(),
      'target_value': _normalize(targetValue),
      'is_active': isActive,
      'sort_order': sortOrder,
    });
  }

  Future<void> createOffer({
    required String imageUrl,
    String? title,
  }) async {
    await _supabase.from('offers').insert({
      'image_url': imageUrl.trim(),
      'title': _normalize(title),
    });
  }

  Future<void> updateOffer({
    required String id,
    required String imageUrl,
    String? title,
  }) async {
    await _supabase.from('offers').update({
      'image_url': imageUrl.trim(),
      'title': _normalize(title),
    }).eq('id', id);
  }

  Future<void> deleteOffer(String id) async {
    await _supabase.from('offers').delete().eq('id', id);
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
    await _supabase.from('banners').update({
      'title': title.trim(),
      'subtitle': _normalize(subtitle),
      'image_url': imageUrl.trim(),
      'target_type': targetType.trim(),
      'target_value': _normalize(targetValue),
      'is_active': isActive,
      'sort_order': sortOrder,
    }).eq('id', id);
  }

  Future<void> deleteBanner(String id) async {
    await _supabase.from('banners').delete().eq('id', id);
  }

  Future<void> reorderBanners(List<AdminBannerModel> banners) async {
    for (var index = 0; index < banners.length; index++) {
      await _supabase
          .from('banners')
          .update({'sort_order': index})
          .eq('id', banners[index].id);
    }
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
        await _supabase.storage.from(bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );
        return _supabase.storage.from(bucket).getPublicUrl(storagePath);
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? 'Could not upload promotion image.';
  }

  String _resolveContentType({
    required String fileName,
    String? mimeType,
  }) {
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
}
