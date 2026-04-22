import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hungry/pages/cart/data/cart_item_model.dart';
import 'package:hungry/pages/cart/data/coupon_service.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:hungry/pages/settings/data/profile_service.dart';

class OrderService {
  OrderService({SupabaseClient? supabase, ProfileService? profileService})
    : _supabase = supabase ?? Supabase.instance.client,
      _profileService = profileService ?? ProfileService();

  final SupabaseClient _supabase;
  final ProfileService _profileService;

  Future<String> createSingleItemOrder({
    required ProductModel product,
    required int quantity,
    int? selectedSize,
    AppliedCoupon? coupon,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final unitPrice = product.effectivePrice;
    final subtotal = unitPrice * quantity;
    const shippingFee = 30.0;
    final discountAmount = coupon?.discountAmount ?? 0.0;
    final totalAmount = subtotal + shippingFee - discountAmount;

    final profile = await _profileService.getProfile();
    final shippingAddress = _composeShippingAddress(profile);

    final orderData = await _supabase
        .from('orders')
        .insert({
          'user_id': user.id,
          'status': 'pending',
          'payment_status': 'pending',
          'delivery_status': 'pending',
          'subtotal': subtotal,
          'shipping_fee': shippingFee,
          'discount_amount': discountAmount,
          'total_amount': totalAmount,
          'currency': 'INR',
          'shipping_address': shippingAddress,
          'notes': coupon == null ? null : 'Coupon: ${coupon.code}',
        })
        .select('id')
        .single();

    final orderId = orderData['id'] as String;

    await _supabase.from('order_items').insert({
      'order_id': orderId,
      'product_id': product.id,
      'product_name': product.name,
      'product_title': product.title,
      'product_image_url': product.primaryImage.isEmpty
          ? null
          : product.primaryImage,
      'unit_price': unitPrice,
      'quantity': quantity,
      'selected_size': selectedSize,
    });

    if (coupon != null) {
      await _supabase.rpc(
        'redeem_coupon_usage',
        params: {'coupon_id_input': coupon.id},
      );
    }

    return orderId;
  }

  Future<String> createCartOrder({required List<CartItemModel> items}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    if (items.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    const shippingFee = 30.0;
    final discountAmount = items.fold<double>(0, (sum, item) {
      if (!item.hasDiscount || item.originalPrice == null) {
        return sum;
      }

      return sum + ((item.originalPrice! - item.price) * item.quantity);
    });
    final totalAmount = subtotal + shippingFee - discountAmount;

    final profile = await _profileService.getProfile();
    final shippingAddress = _composeShippingAddress(profile);

    final orderData = await _supabase
        .from('orders')
        .insert({
          'user_id': user.id,
          'status': 'pending',
          'payment_status': 'pending',
          'delivery_status': 'pending',
          'subtotal': subtotal,
          'shipping_fee': shippingFee,
          'discount_amount': discountAmount,
          'total_amount': totalAmount,
          'currency': 'INR',
          'shipping_address': shippingAddress,
        })
        .select('id')
        .single();

    final orderId = orderData['id'] as String;
    final orderItems = items
        .map(
          (item) => {
            'order_id': orderId,
            'product_id': item.productId,
            'product_name': item.name,
            'product_title': item.productTitle,
            'product_image_url': item.imagePath.isEmpty ? null : item.imagePath,
            'unit_price': item.price,
            'quantity': item.quantity,
            'selected_size': item.size,
          },
        )
        .toList();

    await _supabase.from('order_items').insert(orderItems);

    return orderId;
  }

  String? _composeShippingAddress(dynamic profile) {
    if (profile == null) return null;

    final parts =
        [
              profile.address,
              profile.city,
              profile.state,
              profile.country,
              profile.pincode,
            ]
            .whereType<String>()
            .map((value) => value.trim())
            .where((v) => v.isNotEmpty);

    final joined = parts.join(', ');
    return joined.isEmpty ? null : joined;
  }
}
