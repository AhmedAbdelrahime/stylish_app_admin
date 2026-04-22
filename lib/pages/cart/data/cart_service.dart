import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hungry/pages/cart/data/cart_item_model.dart';
import 'package:hungry/pages/home/data/product_service.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartService {
  CartService({ProductService? productService, SupabaseClient? supabase})
    : _productService = productService ?? ProductService(),
      _supabase = supabase ?? Supabase.instance.client;

  static const String _cartStoragePrefix = 'cart_storage_v1';
  static final ValueNotifier<int> itemCountNotifier = ValueNotifier<int>(0);

  final ProductService _productService;
  final SupabaseClient _supabase;

  bool? _backendAvailable;

  Future<List<CartItemModel>> getCartItems() async {
    if (await _useBackendCart()) {
      await _migrateLocalCartToBackendIfNeeded();
      final backendEntries = await _readBackendEntries();
      final resolvedItems = await _resolveEntries(backendEntries);

      final normalizedEntries = resolvedItems.$1;
      final items = resolvedItems.$2;

      if (_entriesChanged(backendEntries, normalizedEntries)) {
        await _replaceBackendEntries(normalizedEntries);
      }

      return items;
    }

    final storedEntries = await _readLocalEntries();
    final resolvedItems = await _resolveEntries(storedEntries);

    final normalizedEntries = resolvedItems.$1;
    final items = resolvedItems.$2;

    if (_entriesChanged(storedEntries, normalizedEntries)) {
      await _writeLocalEntries(normalizedEntries);
    }

    return items;
  }

  Future<int> syncItemCount() async {
    final items = await getCartItems();
    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);
    if (itemCountNotifier.value != totalItems) {
      itemCountNotifier.value = totalItems;
    }
    return totalItems;
  }

  Future<int> addItem({
    required ProductModel product,
    required int quantity,
    int? selectedSize,
  }) async {
    if (!product.isInStock) {
      throw Exception('This product is currently out of stock.');
    }

    if (await _useBackendCart()) {
      await _migrateLocalCartToBackendIfNeeded();
      final updatedQuantity = await _addBackendItem(
        product: product,
        quantity: quantity,
        selectedSize: selectedSize,
      );
      await syncItemCount();
      return updatedQuantity;
    }

    final addedQuantity = await _addLocalItem(
      product: product,
      quantity: quantity,
      selectedSize: selectedSize,
    );
    await syncItemCount();
    return addedQuantity;
  }

  Future<void> updateQuantity({
    required String productId,
    required int quantity,
    int? selectedSize,
  }) async {
    if (await _useBackendCart()) {
      await _migrateLocalCartToBackendIfNeeded();
      await _updateBackendQuantity(
        productId: productId,
        quantity: quantity,
        selectedSize: selectedSize,
      );
      await syncItemCount();
      return;
    }

    await _updateLocalQuantity(
      productId: productId,
      quantity: quantity,
      selectedSize: selectedSize,
    );
    await syncItemCount();
  }

  Future<void> removeItem({
    required String productId,
    int? selectedSize,
  }) async {
    if (await _useBackendCart()) {
      await _migrateLocalCartToBackendIfNeeded();
      await _deleteBackendEntry(
        productId: productId,
        selectedSize: selectedSize,
      );
      await syncItemCount();
      return;
    }

    await _removeLocalItem(productId: productId, selectedSize: selectedSize);
    await syncItemCount();
  }

  Future<void> clearCart() async {
    if (await _useBackendCart()) {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _clearLocalCart();
        itemCountNotifier.value = 0;
        return;
      }

      await _supabase.from('cart_items').delete().eq('user_id', user.id);
      await _clearLocalCart();
      itemCountNotifier.value = 0;
      return;
    }

    await _clearLocalCart();
    itemCountNotifier.value = 0;
  }

  Future<int> _addBackendItem({
    required ProductModel product,
    required int quantity,
    int? selectedSize,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final existingEntry = await _readSingleBackendEntry(
      productId: product.id,
      selectedSize: selectedSize,
    );

    final mergedQuantity = _normalizeQuantity(
      requestedQuantity: (existingEntry?.quantity ?? 0) + quantity,
      product: product,
    );

    if (existingEntry == null) {
      await _supabase.from('cart_items').insert({
        'user_id': user.id,
        'product_id': product.id,
        'selected_size': selectedSize,
        'quantity': mergedQuantity,
      });
    } else {
      await _updateBackendRowQuantity(existingEntry.rowId!, mergedQuantity);
    }

    return mergedQuantity;
  }

  Future<int> _addLocalItem({
    required ProductModel product,
    required int quantity,
    int? selectedSize,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _readLocalEntries(prefs: prefs);
    final index = entries.indexWhere(
      (entry) =>
          entry.productId == product.id && entry.selectedSize == selectedSize,
    );
    final normalizedQuantity = _normalizeQuantity(
      requestedQuantity: quantity,
      product: product,
    );

    if (index >= 0) {
      final currentEntry = entries[index];
      final mergedQuantity = _normalizeQuantity(
        requestedQuantity: currentEntry.quantity + quantity,
        product: product,
      );
      entries[index] = currentEntry.copyWith(quantity: mergedQuantity);
      await _writeLocalEntries(entries, prefs: prefs);
      return mergedQuantity;
    }

    entries.add(
      _StoredCartEntry(
        productId: product.id,
        selectedSize: selectedSize,
        quantity: normalizedQuantity,
      ),
    );
    await _writeLocalEntries(entries, prefs: prefs);
    return normalizedQuantity;
  }

  Future<void> _updateBackendQuantity({
    required String productId,
    required int quantity,
    int? selectedSize,
  }) async {
    final existingEntry = await _readSingleBackendEntry(
      productId: productId,
      selectedSize: selectedSize,
    );
    if (existingEntry == null) {
      return;
    }

    if (quantity <= 0) {
      await _updateBackendRowQuantity(
        existingEntry.rowId!,
        0,
        deleteWhenZero: true,
      );
      return;
    }

    final product = await _getProductById(productId);
    if (product == null || !product.isInStock) {
      await _updateBackendRowQuantity(
        existingEntry.rowId!,
        0,
        deleteWhenZero: true,
      );
      return;
    }

    final normalizedQuantity = _normalizeQuantity(
      requestedQuantity: quantity,
      product: product,
    );
    await _updateBackendRowQuantity(existingEntry.rowId!, normalizedQuantity);
  }

  Future<void> _updateLocalQuantity({
    required String productId,
    required int quantity,
    int? selectedSize,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _readLocalEntries(prefs: prefs);
    final index = entries.indexWhere(
      (entry) =>
          entry.productId == productId && entry.selectedSize == selectedSize,
    );
    if (index < 0) {
      return;
    }

    if (quantity <= 0) {
      entries.removeAt(index);
      await _writeLocalEntries(entries, prefs: prefs);
      return;
    }

    final product = await _getProductById(productId);
    if (product == null || !product.isInStock) {
      entries.removeAt(index);
      await _writeLocalEntries(entries, prefs: prefs);
      return;
    }

    entries[index] = entries[index].copyWith(
      quantity: _normalizeQuantity(
        requestedQuantity: quantity,
        product: product,
      ),
    );
    await _writeLocalEntries(entries, prefs: prefs);
  }

  Future<void> _deleteBackendEntry({
    required String productId,
    int? selectedSize,
  }) async {
    PostgrestFilterBuilder<dynamic> query = _supabase
        .from('cart_items')
        .delete()
        .eq('product_id', productId);

    if (selectedSize == null) {
      query = query.isFilter('selected_size', null);
    } else {
      query = query.eq('selected_size', selectedSize);
    }

    await query;
  }

  Future<void> _removeLocalItem({
    required String productId,
    int? selectedSize,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _readLocalEntries(prefs: prefs);
    entries.removeWhere(
      (entry) =>
          entry.productId == productId && entry.selectedSize == selectedSize,
    );
    await _writeLocalEntries(entries, prefs: prefs);
  }

  Future<void> _clearLocalCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<(List<_StoredCartEntry>, List<CartItemModel>)> _resolveEntries(
    List<_StoredCartEntry> entries,
  ) async {
    if (entries.isEmpty) {
      return (const <_StoredCartEntry>[], const <CartItemModel>[]);
    }

    final products = await _productService.getProducts();
    final productsById = {for (final product in products) product.id: product};

    final normalizedEntries = <_StoredCartEntry>[];
    final items = <CartItemModel>[];

    for (final entry in entries) {
      final product = productsById[entry.productId];
      if (product == null || !product.isInStock) {
        continue;
      }

      final normalizedQuantity = _normalizeQuantity(
        requestedQuantity: entry.quantity,
        product: product,
      );

      normalizedEntries.add(
        entry.copyWith(quantity: normalizedQuantity, rowId: entry.rowId),
      );
      items.add(
        CartItemModel.fromProduct(
          product: product,
          quantity: normalizedQuantity,
          selectedSize: entry.selectedSize,
        ),
      );
    }

    return (normalizedEntries, items);
  }

  Future<ProductModel?> _getProductById(String productId) async {
    final products = await _productService.getProducts();
    for (final product in products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  int _normalizeQuantity({
    required int requestedQuantity,
    required ProductModel product,
  }) {
    final safeRequestedQuantity = requestedQuantity <= 0
        ? 1
        : requestedQuantity;
    final maxQuantity = product.stockQuantity <= 0 ? 1 : product.stockQuantity;
    return safeRequestedQuantity.clamp(1, maxQuantity).toInt();
  }

  Future<bool> _useBackendCart() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return false;
    }

    if (_backendAvailable != null) {
      return _backendAvailable!;
    }

    try {
      await _supabase.from('cart_items').select('id').limit(1);
      _backendAvailable = true;
      return true;
    } catch (error) {
      if (_isMissingCartTableError(error)) {
        _backendAvailable = false;
        return false;
      }
      rethrow;
    }
  }

  Future<void> _migrateLocalCartToBackendIfNeeded() async {
    final localEntries = await _readLocalEntries();
    if (localEntries.isEmpty) {
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    for (final entry in localEntries) {
      final existingEntry = await _readSingleBackendEntry(
        productId: entry.productId,
        selectedSize: entry.selectedSize,
      );

      if (existingEntry == null) {
        await _supabase.from('cart_items').insert({
          'user_id': user.id,
          'product_id': entry.productId,
          'selected_size': entry.selectedSize,
          'quantity': entry.quantity,
        });
      } else if (entry.quantity > existingEntry.quantity) {
        await _updateBackendRowQuantity(existingEntry.rowId!, entry.quantity);
      }
    }

    await _clearLocalCart();
  }

  Future<List<_StoredCartEntry>> _readBackendEntries() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const [];
    }

    final data = await _supabase
        .from('cart_items')
        .select('id, product_id, quantity, selected_size')
        .eq('user_id', user.id)
        .order('created_at');

    return data
        .whereType<Map>()
        .map(
          (item) => _StoredCartEntry.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<_StoredCartEntry?> _readSingleBackendEntry({
    required String productId,
    int? selectedSize,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    PostgrestFilterBuilder<dynamic> query = _supabase
        .from('cart_items')
        .select('id, product_id, quantity, selected_size')
        .eq('user_id', user.id)
        .eq('product_id', productId);

    if (selectedSize == null) {
      query = query.isFilter('selected_size', null);
    } else {
      query = query.eq('selected_size', selectedSize);
    }

    final data = await query.maybeSingle();
    if (data == null) {
      return null;
    }

    return _StoredCartEntry.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<void> _replaceBackendEntries(List<_StoredCartEntry> entries) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    await _supabase.from('cart_items').delete().eq('user_id', user.id);

    if (entries.isEmpty) {
      return;
    }

    final payload = entries
        .map(
          (entry) => {
            'user_id': user.id,
            'product_id': entry.productId,
            'selected_size': entry.selectedSize,
            'quantity': entry.quantity,
          },
        )
        .toList();

    await _supabase.from('cart_items').insert(payload);
  }

  Future<void> _updateBackendRowQuantity(
    String rowId,
    int quantity, {
    bool deleteWhenZero = false,
  }) async {
    if (deleteWhenZero && quantity <= 0) {
      await _supabase.from('cart_items').delete().eq('id', rowId);
      return;
    }

    await _supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', rowId);
  }

  bool _entriesChanged(
    List<_StoredCartEntry> source,
    List<_StoredCartEntry> normalized,
  ) {
    if (source.length != normalized.length) {
      return true;
    }

    for (var index = 0; index < source.length; index++) {
      if (source[index].productId != normalized[index].productId ||
          source[index].selectedSize != normalized[index].selectedSize ||
          source[index].quantity != normalized[index].quantity) {
        return true;
      }
    }

    return false;
  }

  Future<List<_StoredCartEntry>> _readLocalEntries({
    SharedPreferences? prefs,
  }) async {
    final storage = prefs ?? await SharedPreferences.getInstance();
    final rawJson = storage.getString(_storageKey);
    if (rawJson == null || rawJson.trim().isEmpty) {
      return <_StoredCartEntry>[];
    }

    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      return <_StoredCartEntry>[];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => _StoredCartEntry.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: true);
  }

  Future<void> _writeLocalEntries(
    List<_StoredCartEntry> entries, {
    SharedPreferences? prefs,
  }) async {
    final storage = prefs ?? await SharedPreferences.getInstance();
    final jsonList = entries.map((entry) => entry.toJson()).toList();
    await storage.setString(_storageKey, jsonEncode(jsonList));
  }

  String get _storageKey {
    final userId = _supabase.auth.currentUser?.id ?? 'guest';
    return '$_cartStoragePrefix::$userId';
  }

  bool _isMissingCartTableError(Object error) {
    final message = error.toString();
    return message.contains("Could not find the table 'public.cart_items'") ||
        message.contains('PGRST205') ||
        message.contains('42P01') ||
        message.contains('relation "public.cart_items" does not exist');
  }
}

class _StoredCartEntry {
  const _StoredCartEntry({
    required this.productId,
    required this.quantity,
    this.selectedSize,
    this.rowId,
  });

  final String productId;
  final int quantity;
  final int? selectedSize;
  final String? rowId;

  factory _StoredCartEntry.fromJson(Map<String, dynamic> json) {
    return _StoredCartEntry(
      rowId: json['id']?.toString(),
      productId: (json['product_id'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      selectedSize: (json['selected_size'] as num?)?.toInt(),
    );
  }

  _StoredCartEntry copyWith({int? quantity, String? rowId}) {
    return _StoredCartEntry(
      rowId: rowId ?? this.rowId,
      productId: productId,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': rowId,
      'product_id': productId,
      'quantity': quantity,
      'selected_size': selectedSize,
    };
  }
}
