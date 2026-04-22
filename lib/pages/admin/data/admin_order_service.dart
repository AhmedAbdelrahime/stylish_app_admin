import 'package:hungry/pages/admin/data/admin_order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrderService {
  AdminOrderService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<List<AdminOrderModel>> getOrders() async {
    final data = await _supabase
        .from('orders')
        .select(
          '''
          *,
          profile:profiles!orders_user_id_fkey(
            id,
            email,
            full_name,
            image,
            address,
            city,
            state,
            country,
            pincode,
            role
          ),
          order_items(*)
          ''',
        )
        .order('created_at', ascending: false);

    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AdminOrderModel.fromJson)
        .toList();
  }

  Future<void> updateOrderStatuses({
    required String orderId,
    String? status,
    String? paymentStatus,
    String? deliveryStatus,
  }) async {
    final payload = <String, dynamic>{};
    if (status != null) {
      payload['status'] = status.trim();
    }
    if (paymentStatus != null) {
      payload['payment_status'] = paymentStatus.trim();
    }
    if (deliveryStatus != null) {
      payload['delivery_status'] = deliveryStatus.trim();
    }
    if (payload.isEmpty) return;

    await _supabase.from('orders').update(payload).eq('id', orderId);
  }
}
