import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistService {
  WishlistService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  bool? _backendAvailable;

  Future<Set<String>> getWishlistProductIds() async {
    if (!await _useBackendWishlist()) {
      return <String>{};
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return <String>{};
    }

    final data = await _supabase
        .from('wishlist_items')
        .select('product_id')
        .eq('user_id', user.id)
        .order('created_at');

    return data
        .whereType<Map>()
        .map((item) => item['product_id']?.toString() ?? '')
        .where((productId) => productId.isNotEmpty)
        .toSet();
  }

  Future<bool> toggle(String productId) async {
    if (!await _useBackendWishlist()) {
      throw Exception(
        'The wishlist_items table is missing in Supabase. Run the new migration first.',
      );
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final existing = await _supabase
        .from('wishlist_items')
        .select('id')
        .eq('user_id', user.id)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('wishlist_items').insert({
        'user_id': user.id,
        'product_id': productId,
      });
      return true;
    }

    await _supabase.from('wishlist_items').delete().eq('id', existing['id']);
    return false;
  }

  Future<void> clearForCurrentUser() async {
    if (!await _useBackendWishlist()) {
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    await _supabase.from('wishlist_items').delete().eq('user_id', user.id);
  }

  Future<bool> _useBackendWishlist() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return false;
    }

    if (_backendAvailable != null) {
      return _backendAvailable!;
    }

    try {
      await _supabase.from('wishlist_items').select('id').limit(1);
      _backendAvailable = true;
      return true;
    } catch (error) {
      if (_isMissingWishlistTableError(error)) {
        _backendAvailable = false;
        return false;
      }
      rethrow;
    }
  }

  bool _isMissingWishlistTableError(Object error) {
    final message = error.toString();
    return message.contains("Could not find the table 'public.wishlist_items'") ||
        message.contains('PGRST205') ||
        message.contains('42P01') ||
        message.contains('relation "public.wishlist_items" does not exist');
  }
}
