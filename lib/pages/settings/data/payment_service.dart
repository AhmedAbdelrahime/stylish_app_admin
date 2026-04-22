import 'package:flutter/foundation.dart';
import 'package:hungry/pages/settings/data/pyment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('payment_methods')
          .select()
          .eq('user_id', user.id);

      return (data as List)
          .map((item) => PaymentMethod.fromJson(item))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching payment methods: $e');
      }
      return [];
    }
  }

  Future<void> addPaymentMethod(AddPaymentMethodDto dto) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('payment_methods').insert({
      ...dto.toJson(),
      'user_id': user.id,
    });
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase
        .from('payment_methods')
        .delete()
        .eq('id', paymentMethodId)
        .eq('user_id', user.id);
  }
}
