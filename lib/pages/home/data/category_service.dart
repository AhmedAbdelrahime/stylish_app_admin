import 'package:flutter/foundation.dart';
import 'package:hungry/pages/home/models/category_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _categoryBucket = 'categories';

  Future<List<CategoryModel>> getCategories() async {
    debugPrint('[CategoryService] getCategories:start');
    try {
      final data = await _supabase
          .from('categories')
          .select()
          .order('sort_order')
          .order('created_at');

      debugPrint('[CategoryService] getCategories:sorted_success');
      return _mapCategories(data);
    } catch (error, stackTrace) {
      debugPrint('[CategoryService] getCategories:sorted_error $error');
      debugPrintStack(
        label: '[CategoryService] getCategories:sorted_stack',
        stackTrace: stackTrace,
      );
      final data = await _supabase
          .from('categories')
          .select()
          .order('created_at');
      debugPrint('[CategoryService] getCategories:fallback_success');
      return _mapCategories(data);
    }
  }

  List<CategoryModel> _mapCategories(dynamic data) {
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String imageUrl,
    bool isVisible = true,
    int sortOrder = 0,
  }) async {
    debugPrint(
      '[CategoryService] createCategory:start name="$name" isVisible=$isVisible sortOrder=$sortOrder',
    );
    try {
      final data = await _supabase
          .from('categories')
          .insert(
            _buildPayload(
              name: name,
              imageUrl: imageUrl,
              isVisible: isVisible,
              sortOrder: sortOrder,
            ),
          )
          .select()
          .single();
      debugPrint('[CategoryService] createCategory:modern_success');
      return CategoryModel.fromJson(data);
    } catch (error, stackTrace) {
      debugPrint('[CategoryService] createCategory:modern_error $error');
      debugPrintStack(
        label: '[CategoryService] createCategory:modern_stack',
        stackTrace: stackTrace,
      );
      final data = await _supabase
          .from('categories')
          .insert(_buildLegacyPayload(name: name, imageUrl: imageUrl))
          .select()
          .single();
      debugPrint('[CategoryService] createCategory:legacy_success');
      return CategoryModel.fromJson(data);
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String imageUrl,
    bool isVisible = true,
    int sortOrder = 0,
  }) async {
    debugPrint(
      '[CategoryService] updateCategory:start id=$id name="$name" isVisible=$isVisible sortOrder=$sortOrder',
    );
    try {
      await _supabase
          .from('categories')
          .update(
            _buildPayload(
              name: name,
              imageUrl: imageUrl,
              isVisible: isVisible,
              sortOrder: sortOrder,
            ),
          )
          .eq('id', id);
      debugPrint('[CategoryService] updateCategory:modern_success');
    } catch (error, stackTrace) {
      debugPrint('[CategoryService] updateCategory:modern_error $error');
      debugPrintStack(
        label: '[CategoryService] updateCategory:modern_stack',
        stackTrace: stackTrace,
      );
      await _supabase
          .from('categories')
          .update(_buildLegacyPayload(name: name, imageUrl: imageUrl))
          .eq('id', id);
      debugPrint('[CategoryService] updateCategory:legacy_success');
    }
  }

  Future<void> updateCategoryVisibility({
    required String id,
    required bool isVisible,
  }) async {
    try {
      await _supabase
          .from('categories')
          .update({'is_visible': isVisible})
          .eq('id', id);
    } catch (error, stackTrace) {
      debugPrint('[CategoryService] updateCategoryVisibility:error $error');
      debugPrintStack(
        label: '[CategoryService] updateCategoryVisibility:stack',
        stackTrace: stackTrace,
      );
      // Gracefully ignore when the column does not exist yet.
    }
  }

  Future<void> updateCategorySortOrder({
    required String id,
    required int sortOrder,
  }) async {
    try {
      await _supabase
          .from('categories')
          .update({'sort_order': sortOrder})
          .eq('id', id);
    } catch (error, stackTrace) {
      debugPrint('[CategoryService] updateCategorySortOrder:error $error');
      debugPrintStack(
        label: '[CategoryService] updateCategorySortOrder:stack',
        stackTrace: stackTrace,
      );
      // Gracefully ignore when the column does not exist yet.
    }
  }

  Future<void> reorderCategories(List<CategoryModel> categories) async {
    final payload = <Map<String, dynamic>>[
      for (var index = 0; index < categories.length; index++)
        {
          'id': categories[index].id,
          'sort_order': index,
        },
    ];

    try {
      await _supabase.from('categories').upsert(payload, onConflict: 'id');
      debugPrint('[CategoryService] reorderCategories:success count=${payload.length}');
    } catch (error, stackTrace) {
      debugPrint('[CategoryService] reorderCategories:error $error');
      debugPrintStack(
        label: '[CategoryService] reorderCategories:stack',
        stackTrace: stackTrace,
      );
      for (final row in payload) {
        await _supabase
            .from('categories')
            .update({'sort_order': row['sort_order']})
            .eq('id', row['id'] as String);
      }
      debugPrint('[CategoryService] reorderCategories:fallback_success');
    }
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from('categories').delete().eq('id', id);
  }

  Future<String> uploadCategoryImage(XFile file) async {
    debugPrint(
      '[CategoryService] uploadCategoryImage:start file=${file.name} mime=${file.mimeType}',
    );
    final bytes = await file.readAsBytes();
    return uploadCategoryImageBytes(
      bytes: bytes,
      fileName: file.name,
      mimeType: file.mimeType,
    );
  }

  Future<String> uploadCategoryImageBytes({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    debugPrint(
      '[CategoryService] uploadCategoryImageBytes:start file=$fileName mime=$mimeType bytes=${bytes.length}',
    );
    final generatedFileName = _buildImageNameFromName(fileName);
    final resolvedPath = 'categories/$generatedFileName';

    await _supabase.storage
        .from(_categoryBucket)
        .uploadBinary(
          resolvedPath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _resolveContentType(fileName, mimeType),
          ),
        );

    final publicUrl = _supabase.storage
        .from(_categoryBucket)
        .getPublicUrl(resolvedPath);
    debugPrint(
      '[CategoryService] uploadCategoryImageBytes:success filePath=$resolvedPath publicUrl=$publicUrl',
    );
    return publicUrl;
  }

  String _buildImageNameFromName(String originalName) {
    final extension = path.extension(originalName).toLowerCase();
    final safeExtension = extension.isEmpty ? '.png' : extension;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'category_$timestamp$safeExtension';
  }

  String _resolveContentType(String fileName, String? mimeType) {
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

  Map<String, dynamic> _buildPayload({
    required String name,
    required String imageUrl,
    required bool isVisible,
    required int sortOrder,
  }) {
    return {
      ..._buildLegacyPayload(name: name, imageUrl: imageUrl),
      'is_visible': isVisible,
      'sort_order': sortOrder,
    };
  }

  Map<String, dynamic> _buildLegacyPayload({
    required String name,
    required String imageUrl,
  }) {
    return <String, dynamic>{
      'name': name.trim(),
      'image_url': _normalize(imageUrl),
    };
  }
}
