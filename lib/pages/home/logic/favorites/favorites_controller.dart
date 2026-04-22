import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hungry/pages/home/data/wishlist_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController._({WishlistService? service})
    : _service = service ?? WishlistService() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session == null) {
        _favoriteProductIds.clear();
        _isLoading = false;
        notifyListeners();
        return;
      }

      loadFavorites();
    });

    loadFavorites();
  }

  static final FavoritesController instance = FavoritesController._();

  final WishlistService _service;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Set<String> _favoriteProductIds = <String>{};
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isLoading = false;

  Set<String> get favoriteProductIds => Set.unmodifiable(_favoriteProductIds);

  int get count => _favoriteProductIds.length;

  bool get isLoading => _isLoading;

  bool isFavorite(String productId) => _favoriteProductIds.contains(productId);

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final productIds = await _service.getWishlistProductIds();
      _favoriteProductIds
        ..clear()
        ..addAll(productIds);
    } catch (error) {
      debugPrint('Error loading wishlist: $error');
      _favoriteProductIds.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggle(String productId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    final wasFavorite = _favoriteProductIds.contains(productId);
    if (wasFavorite) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    notifyListeners();

    try {
      final isFavorite = await _service.toggle(productId);

      if (isFavorite) {
        _favoriteProductIds.add(productId);
      } else {
        _favoriteProductIds.remove(productId);
      }
    } catch (error) {
      debugPrint('Error updating wishlist: $error');
      if (wasFavorite) {
        _favoriteProductIds.add(productId);
      } else {
        _favoriteProductIds.remove(productId);
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
