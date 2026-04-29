import 'package:flutter/foundation.dart';
import 'package:hungry/pages/admin/data/admin_audit_service.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _productBucket = 'product-images';
  static const String _productFallbackBucket = 'products';
  static const String _sharedFallbackBucket = 'categories';

  Future<List<ProductModel>> getProducts() async {
    try {
      final visibleProducts = await _fetchProducts(excludeHidden: true);
      if (visibleProducts.isNotEmpty) {
        return visibleProducts;
      }

      // Fallback so the storefront still works if current rows do not use
      // the expected status values yet.
      return await _fetchProducts(excludeHidden: false);
    } catch (error) {
      debugPrint('Error fetching products: $error');
      return [];
    }
  }

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final data = await _supabase
          .from('products')
          .select()
          .order('featured', ascending: false)
          .order('created_at', ascending: false);

      return _mapProducts(data);
    } catch (error) {
      debugPrint('Error fetching all products: $error');
      return [];
    }
  }

  Future<List<ProductModel>> getDashboardProducts() async {
    try {
      final data = await _supabase
          .from('products')
          .select(
            'id, category_id, stock_quantity, low_stock_threshold, status, featured, main_image_url, image_urls',
          )
          .order('featured', ascending: false)
          .order('created_at', ascending: false);

      return _mapProducts(data);
    } catch (error) {
      debugPrint('Error fetching dashboard products: $error');
      return [];
    }
  }

  Future<void> assignProductsToCategory({
    required String categoryId,
    required List<String> productIds,
  }) async {
    await _supabase
        .from('products')
        .update({'category_id': null})
        .eq('category_id', categoryId);

    if (productIds.isEmpty) return;

    await _supabase
        .from('products')
        .update({'category_id': categoryId})
        .inFilter('id', productIds);

    await _logAuditEvent(
      action: 'assign_products_to_category',
      entityType: 'product',
      entityId: categoryId,
      details: {'category_id': categoryId, 'product_ids': productIds},
    );
  }

  Future<ProductModel> createProduct({
    required String name,
    required String title,
    required String description,
    required double price,
    double? salePrice,
    required double rating,
    required List<int> sizes,
    required String? categoryId,
    required int stockQuantity,
    required int lowStockThreshold,
    required String status,
    required bool featured,
    String? mainImageUrl,
    List<String> imageUrls = const [],
    String? sku,
  }) async {
    final payload = _buildPayload(
      name: name,
      title: title,
      description: description,
      price: price,
      salePrice: salePrice,
      rating: rating,
      sizes: sizes,
      categoryId: categoryId,
      stockQuantity: stockQuantity,
      lowStockThreshold: lowStockThreshold,
      status: status,
      featured: featured,
      mainImageUrl: mainImageUrl,
      imageUrls: imageUrls,
      sku: sku,
    );

    final data = await _supabase
        .from('products')
        .insert(payload)
        .select()
        .single();

    await _logAuditEvent(
      action: 'create_product',
      entityType: 'product',
      entityId: data['id']?.toString(),
      details: payload,
    );

    return ProductModel.fromJson(data);
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required String title,
    required String description,
    required double price,
    double? salePrice,
    required double rating,
    required List<int> sizes,
    required String? categoryId,
    required int stockQuantity,
    required int lowStockThreshold,
    required String status,
    required bool featured,
    String? mainImageUrl,
    List<String> imageUrls = const [],
    String? sku,
  }) async {
    final payload = _buildPayload(
      name: name,
      title: title,
      description: description,
      price: price,
      salePrice: salePrice,
      rating: rating,
      sizes: sizes,
      categoryId: categoryId,
      stockQuantity: stockQuantity,
      lowStockThreshold: lowStockThreshold,
      status: status,
      featured: featured,
      mainImageUrl: mainImageUrl,
      imageUrls: imageUrls,
      sku: sku,
    );

    await _supabase.from('products').update(payload).eq('id', id);

    await _logAuditEvent(
      action: 'update_product',
      entityType: 'product',
      entityId: id,
      details: payload,
    );
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);

    await _logAuditEvent(
      action: 'delete_product',
      entityType: 'product',
      entityId: id,
      details: {'id': id},
    );
  }

  Future<void> deleteProducts(List<String> ids) async {
    if (ids.isEmpty) return;
    await _supabase.from('products').delete().inFilter('id', ids);

    await _logAuditEvent(
      action: 'bulk_delete_products',
      entityType: 'product',
      details: {'ids': ids},
    );
  }

  Future<void> bulkUpdateProducts({
    required List<String> ids,
    String? status,
    bool? featured,
  }) async {
    if (ids.isEmpty) return;

    final payload = <String, dynamic>{};
    if (status != null) {
      payload['status'] = status.trim();
    }
    if (featured != null) {
      payload['featured'] = featured;
    }
    if (payload.isEmpty) return;

    await _supabase.from('products').update(payload).inFilter('id', ids);

    await _logAuditEvent(
      action: 'bulk_update_products',
      entityType: 'product',
      details: {'ids': ids, ...payload},
    );
  }

  Future<String> uploadProductImage(XFile file) async {
    final bytes = await file.readAsBytes();
    return uploadProductImageBytes(
      bytes: bytes,
      fileName: file.name,
      mimeType: file.mimeType,
    );
  }

  Future<String> uploadProductImageBytes({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    final resolvedFileName = _buildImageNameFromName(fileName);
    final filePath = 'products/$resolvedFileName';
    final contentType = _resolveContentTypeFromName(
      fileName: fileName,
      mimeType: mimeType,
    );

    try {
      return await _uploadToBucket(
        bucket: _productBucket,
        filePath: filePath,
        bytes: bytes,
        contentType: contentType,
      );
    } catch (error) {
      debugPrint('[ProductService] uploadProductImage:primary_error $error');
      try {
        return await _uploadToBucket(
          bucket: _productFallbackBucket,
          filePath: filePath,
          bytes: bytes,
          contentType: contentType,
        );
      } catch (fallbackError) {
        debugPrint(
          '[ProductService] uploadProductImage:fallback_error bucket=$_productFallbackBucket error=$fallbackError',
        );
        return _uploadToBucket(
          bucket: _sharedFallbackBucket,
          filePath: filePath,
          bytes: bytes,
          contentType: contentType,
        );
      }
    }
  }

  Future<String> _uploadToBucket({
    required String bucket,
    required String filePath,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _supabase.storage
        .from(bucket)
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: contentType),
        );
    debugPrint(
      '[ProductService] uploadProductImage:success bucket=$bucket path=$filePath',
    );
    return _supabase.storage.from(bucket).getPublicUrl(filePath);
  }

  Future<List<ProductModel>> _fetchProducts({
    required bool excludeHidden,
  }) async {
    PostgrestFilterBuilder<List<dynamic>> query = _supabase
        .from('products')
        .select();

    if (excludeHidden) {
      query = query.neq('status', 'hidden');
    }

    final data = await query
        .order('featured', ascending: false)
        .order('created_at', ascending: false);

    return _mapProducts(data);
  }

  List<ProductModel> _mapProducts(dynamic data) {
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  Map<String, dynamic> _buildPayload({
    required String name,
    required String title,
    required String description,
    required double price,
    double? salePrice,
    required double rating,
    required List<int> sizes,
    required String? categoryId,
    required int stockQuantity,
    required int lowStockThreshold,
    required String status,
    required bool featured,
    String? mainImageUrl,
    required List<String> imageUrls,
    String? sku,
  }) {
    return {
      'name': name.trim(),
      'title': title.trim(),
      'description': description.trim(),
      'price': price,
      'sale_price': salePrice,
      'rating': rating,
      'sizes': sizes,
      'category_id': _normalize(categoryId),
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'status': status.trim(),
      'featured': featured,
      'main_image_url': _normalize(mainImageUrl),
      'image_urls': imageUrls.where((url) => url.trim().isNotEmpty).toList(),
      'sku': _normalize(sku),
    };
  }

  String _buildImageNameFromName(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    final safeExtension = extension.isEmpty ? '.png' : extension;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'product_$timestamp$safeExtension';
  }

  String _resolveContentTypeFromName({
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
    } catch (error) {
      debugPrint('[ProductService] audit_log_error: $error');
    }
  }
}
