import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/core/realtime/supabase_realtime_reloader.dart';
import 'package:hungry/pages/admin/data/admin_product_import_service.dart';
import 'package:hungry/pages/home/data/category_service.dart';
import 'package:hungry/pages/home/data/product_service.dart';
import 'package:hungry/pages/home/models/category_model.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_product_state.dart';

class AdminProductCubit extends Cubit<AdminProductState> {
  AdminProductCubit({
    ProductService? productService,
    CategoryService? categoryService,
  }) : _productService = productService ?? ProductService(),
       _categoryService = categoryService ?? CategoryService(),
       super(const AdminProductState()) {
    _setupRealtime();
  }

  final ProductService _productService;
  final CategoryService _categoryService;
  SupabaseRealtimeReloader? _realtimeReloader;
  bool _isImporting = false;

  void _setupRealtime() {
    _realtimeReloader = SupabaseRealtimeReloader(
      supabase: Supabase.instance.client,
      channelName: 'admin-products-${DateTime.now().microsecondsSinceEpoch}',
      tables: const ['products', 'categories'],
      onReload: () async {
        if (state.isSaving ||
            state.isDeleting ||
            state.isBulkUpdating ||
            _isImporting) {
          return;
        }
        try {
          await loadData(showLoading: false);
        } catch (_) {
          // Keep realtime polling resilient; failures should not crash the cubit.
        }
      },
    );
  }

  @override
  Future<void> close() {
    _realtimeReloader?.dispose();
    return super.close();
  }

  Future<void> loadData({bool showLoading = true}) async {
    if (isClosed) return;

    if (showLoading) {
      emit(state.copyWith(isLoading: true));
    }

    try {
      final results = await Future.wait([
        _productService.getAllProducts(),
        _categoryService.getCategories(),
      ]);
      final products = results[0] as List<ProductModel>;
      final categories = results[1] as List<CategoryModel>;
      final validProductIds = products.map((product) => product.id).toSet();
      final selectedProductIds = state.selectedProductIds
          .where(validProductIds.contains)
          .toSet();

      if (isClosed) return;
      emit(
        state.copyWith(
          products: products,
          categories: categories,
          selectedProductIds: selectedProductIds,
          isLoading: false,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false));
      }
      rethrow;
    }
  }

  void toggleProductSelection(String productId, bool selected) {
    final nextSelectedIds = {...state.selectedProductIds};
    if (selected) {
      nextSelectedIds.add(productId);
    } else {
      nextSelectedIds.remove(productId);
    }
    emit(state.copyWith(selectedProductIds: nextSelectedIds));
  }

  void toggleVisibleProductSelection({
    required Iterable<String> productIds,
    required bool selected,
  }) {
    final visibleIds = productIds.toSet();
    final nextSelectedIds = {...state.selectedProductIds};
    if (selected) {
      nextSelectedIds.addAll(visibleIds);
    } else {
      nextSelectedIds.removeWhere(visibleIds.contains);
    }
    emit(state.copyWith(selectedProductIds: nextSelectedIds));
  }

  void clearSelectedProducts() {
    if (state.selectedProductIds.isEmpty) return;
    emit(state.copyWith(selectedProductIds: <String>{}));
  }

  Future<void> saveProduct(AdminProductSaveInput input) async {
    if (state.isSaving) return;
    emit(state.copyWith(isSaving: true));

    try {
      var mainImageUrl = input.mainImageUrl.trim().isEmpty
          ? input.editingProduct?.mainImageUrl
          : input.mainImageUrl.trim();

      if (input.selectedImage != null) {
        if (input.selectedImageBytes != null) {
          mainImageUrl = await _productService.uploadProductImageBytes(
            bytes: input.selectedImageBytes!,
            fileName: input.selectedImage!.name,
            mimeType: input.selectedImage!.mimeType,
          );
        } else {
          mainImageUrl = await _productService.uploadProductImage(
            input.selectedImage!,
          );
        }
      }

      final uploadedGalleryUrls = <String>[];
      final galleryUploadCount = input.selectedGalleryImages.length;
      for (var index = 0; index < galleryUploadCount; index++) {
        final galleryImage = input.selectedGalleryImages[index];
        final galleryImageBytes = input.selectedGalleryImageBytes[index];
        final uploadedUrl = await _productService.uploadProductImageBytes(
          bytes: galleryImageBytes,
          fileName: galleryImage.name,
          mimeType: galleryImage.mimeType,
        );
        uploadedGalleryUrls.add(uploadedUrl);
      }

      final normalizedGalleryUrls = [
        ...input.existingGalleryUrls,
        ...uploadedGalleryUrls,
      ].where((url) => url.trim().isNotEmpty).toSet().toList();

      if (input.editingProduct == null) {
        await _productService.createProduct(
          name: input.name,
          title: input.title,
          description: input.description,
          price: input.price,
          salePrice: input.salePrice,
          rating: input.rating,
          sizes: input.sizes,
          categoryId: input.categoryId,
          stockQuantity: input.stockQuantity,
          lowStockThreshold: input.lowStockThreshold,
          status: input.status,
          featured: input.featured,
          mainImageUrl: mainImageUrl,
          imageUrls: normalizedGalleryUrls,
          sku: input.sku,
        );
      } else {
        await _productService.updateProduct(
          id: input.editingProduct!.id,
          name: input.name,
          title: input.title,
          description: input.description,
          price: input.price,
          salePrice: input.salePrice,
          rating: input.rating,
          sizes: input.sizes,
          categoryId: input.categoryId,
          stockQuantity: input.stockQuantity,
          lowStockThreshold: input.lowStockThreshold,
          status: input.status,
          featured: input.featured,
          mainImageUrl: mainImageUrl,
          imageUrls: normalizedGalleryUrls,
          sku: input.sku,
        );
      }

      await loadData(showLoading: false);
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> deleteProduct(ProductModel product) async {
    if (state.isDeleting) return;
    emit(state.copyWith(isDeleting: true));

    try {
      await _productService.deleteProduct(product.id);
      await loadData(showLoading: false);
    } finally {
      emit(state.copyWith(isDeleting: false));
    }
  }

  Future<void> bulkUpdateSelectedProducts({
    String? status,
    bool? featured,
  }) async {
    if (state.selectedProductIds.isEmpty || state.isBulkUpdating) return;

    emit(state.copyWith(isBulkUpdating: true));
    try {
      await _productService.bulkUpdateProducts(
        ids: state.selectedProductIds.toList(),
        status: status,
        featured: featured,
      );
      await loadData(showLoading: false);
      clearSelectedProducts();
    } finally {
      emit(state.copyWith(isBulkUpdating: false));
    }
  }

  Future<void> deleteSelectedProducts() async {
    if (state.selectedProductIds.isEmpty || state.isBulkUpdating) return;

    emit(state.copyWith(isBulkUpdating: true));
    try {
      await _productService.deleteProducts(state.selectedProductIds.toList());
      await loadData(showLoading: false);
      clearSelectedProducts();
    } finally {
      emit(state.copyWith(isBulkUpdating: false));
    }
  }

  Future<AdminProductImportResult> importRows({
    required List<AdminProductImportRow> rows,
    required int invalidRowCount,
    required AdminMissingCategoryImportStrategy strategy,
  }) async {
    _isImporting = true;
    try {
      var categories = state.categories;

      if (strategy == AdminMissingCategoryImportStrategy.createCategories) {
        final missingCategoryNames =
            rows
                .where(
                  (row) =>
                      row.isValid &&
                      row.hasMissingCategory &&
                      (row.requestedCategoryName?.isNotEmpty ?? false),
                )
                .map((row) => row.requestedCategoryName!.trim())
                .toSet()
                .toList()
              ..sort();

        for (final categoryName in missingCategoryNames) {
          final exists = categories.any(
            (category) =>
                category.name.trim().toLowerCase() ==
                categoryName.toLowerCase(),
          );
          if (!exists) {
            await _categoryService.createCategory(
              name: categoryName,
              imageUrl: 'https://placehold.co/600x400/png',
            );
          }
        }

        if (missingCategoryNames.isNotEmpty) {
          categories = await _categoryService.getCategories();
        }
      }

      final categoryIdsByName = {
        for (final category in categories)
          category.name.trim().toLowerCase(): category.id,
      };

      var importedCount = 0;
      var skippedCount = invalidRowCount;
      var uncategorizedDraftCount = 0;

      for (final row in rows) {
        if (!row.isValid || row.price == null) {
          continue;
        }

        var categoryId = row.categoryId;
        var status = row.status;

        if (row.hasMissingCategory) {
          switch (strategy) {
            case AdminMissingCategoryImportStrategy.createCategories:
              final categoryName = row.requestedCategoryName
                  ?.trim()
                  .toLowerCase();
              if (categoryName == null || categoryName.isEmpty) {
                skippedCount += 1;
                continue;
              }
              categoryId = categoryIdsByName[categoryName];
              if (categoryId == null) {
                skippedCount += 1;
                continue;
              }
              break;
            case AdminMissingCategoryImportStrategy.importAsDraftUncategorized:
              categoryId = null;
              status = 'draft';
              uncategorizedDraftCount += 1;
              break;
            case AdminMissingCategoryImportStrategy.skipRows:
              skippedCount += 1;
              continue;
          }
        }

        await _productService.createProduct(
          name: row.name,
          title: row.title,
          description: row.description,
          price: row.price!,
          salePrice: row.salePrice,
          rating: row.rating,
          sizes: row.sizes,
          categoryId: categoryId,
          stockQuantity: row.stockQuantity,
          lowStockThreshold: row.lowStockThreshold,
          status: status,
          featured: row.featured,
          mainImageUrl: row.mainImageUrl,
          imageUrls: row.imageUrls,
          sku: row.sku,
        );

        importedCount += 1;
      }

      await loadData(showLoading: false);

      return AdminProductImportResult(
        importedCount: importedCount,
        skippedCount: skippedCount,
        uncategorizedDraftCount: uncategorizedDraftCount,
      );
    } finally {
      _isImporting = false;
    }
  }
}

class AdminProductSaveInput {
  const AdminProductSaveInput({
    required this.editingProduct,
    required this.name,
    required this.title,
    required this.description,
    required this.price,
    required this.salePrice,
    required this.rating,
    required this.sizes,
    required this.categoryId,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.status,
    required this.featured,
    required this.mainImageUrl,
    required this.selectedImage,
    required this.selectedImageBytes,
    required this.existingGalleryUrls,
    required this.selectedGalleryImages,
    required this.selectedGalleryImageBytes,
    required this.sku,
  });

  final ProductModel? editingProduct;
  final String name;
  final String title;
  final String description;
  final double price;
  final double? salePrice;
  final double rating;
  final List<int> sizes;
  final String? categoryId;
  final int stockQuantity;
  final int lowStockThreshold;
  final String status;
  final bool featured;
  final String mainImageUrl;
  final XFile? selectedImage;
  final Uint8List? selectedImageBytes;
  final List<String> existingGalleryUrls;
  final List<XFile> selectedGalleryImages;
  final List<Uint8List> selectedGalleryImageBytes;
  final String sku;
}

enum AdminMissingCategoryImportStrategy {
  createCategories,
  importAsDraftUncategorized,
  skipRows,
}

class AdminProductImportResult {
  const AdminProductImportResult({
    required this.importedCount,
    required this.skippedCount,
    required this.uncategorizedDraftCount,
  });

  final int importedCount;
  final int skippedCount;
  final int uncategorizedDraftCount;
}
