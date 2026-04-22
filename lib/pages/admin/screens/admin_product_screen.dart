import 'dart:io';

import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/admin/data/admin_product_import_service.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/home/data/category_service.dart';
import 'package:hungry/pages/home/data/product_service.dart';
import 'package:hungry/pages/home/models/category_model.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:image_picker/image_picker.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  List<excel.CellValue> get _excelHeaderRow => [
    excel.TextCellValue('id'),
    excel.TextCellValue('sku'),
    excel.TextCellValue('name'),
    excel.TextCellValue('title'),
    excel.TextCellValue('description'),
    excel.TextCellValue('category_name'),
    excel.TextCellValue('category_id'),
    excel.TextCellValue('price'),
    excel.TextCellValue('sale_price'),
    excel.TextCellValue('rating'),
    excel.TextCellValue('stock_quantity'),
    excel.TextCellValue('low_stock_threshold'),
    excel.TextCellValue('status'),
    excel.TextCellValue('featured'),
    excel.TextCellValue('sizes'),
    excel.TextCellValue('main_image_url'),
    excel.TextCellValue('gallery_urls'),
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController(
    text: '4.5',
  );
  final TextEditingController _sizesController = TextEditingController(
    text: '38,39,40,41',
  );
  final TextEditingController _stockController = TextEditingController(
    text: '0',
  );
  final TextEditingController _lowStockController = TextEditingController(
    text: '5',
  );
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _mainImageUrlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isPickingImage = false;
  bool _isImporting = false;
  bool _isExporting = false;
  bool _isBulkUpdating = false;
  bool _isFeatured = false;

  List<ProductModel> _products = const [];
  List<CategoryModel> _categories = const [];
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final List<XFile> _selectedGalleryImages = <XFile>[];
  final List<Uint8List> _selectedGalleryImageBytes = <Uint8List>[];
  final List<String> _galleryImageUrls = <String>[];
  ProductModel? _editingProduct;
  String? _selectedCategoryId;
  String _selectedStatus = 'active';
  String _searchQuery = '';
  String? _categoryFilter;
  String? _importedFileName;
  _ProductImportPreview? _importPreview;
  final Set<String> _selectedProductIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _ratingController.dispose();
    _sizesController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    _skuController.dispose();
    _mainImageUrlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _productService.getAllProducts(),
        _categoryService.getCategories(),
      ]);

      if (!mounted) return;
      setState(() {
        _products = results[0] as List<ProductModel>;
        _categories = results[1] as List<CategoryModel>;
        _selectedProductIds.removeWhere(
          (id) => !_products.any((product) => product.id == id),
        );
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isPickingImage = true);
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: 'Failed to pick product image.',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      setState(() => _isPickingImage = true);
      final pickedImages = await _imagePicker.pickMultiImage(imageQuality: 80);

      if (pickedImages.isEmpty) return;

      final imageBytes = await Future.wait(
        pickedImages.map((image) => image.readAsBytes()),
      );
      if (!mounted) return;

      setState(() {
        _selectedGalleryImages.addAll(pickedImages);
        _selectedGalleryImageBytes.addAll(imageBytes);
      });
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: 'Failed to pick gallery images.',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _pickImportSheet() async {
    if (_isImporting) return;

    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowedExtensions: const ['csv', 'xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw 'Could not read the selected file.';
      }

      final rows = const AdminProductImportService().parseRows(
        bytes: bytes,
        extension: file.extension?.toLowerCase() ?? '',
        categories: _categories,
      );

      if (rows.isEmpty) {
        throw 'The selected sheet does not contain any product rows.';
      }

      if (!mounted) return;
      setState(() {
        _importedFileName = file.name;
        _importPreview = _ProductImportPreview(
          fileName: file.name,
          rows: rows,
          invalidRowCount: rows.where((row) => !row.isValid).length,
        );
      });
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _confirmSheetImport(
    _MissingCategoryImportStrategy strategy,
  ) async {
    final preview = _importPreview;
    if (preview == null || _isImporting) return;

    setState(() => _isImporting = true);

    try {
      var categories = _categories;

      if (strategy == _MissingCategoryImportStrategy.createCategories) {
        final missingCategoryNames =
            preview.rows
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
      var skippedCount = preview.invalidRowCount;
      var uncategorizedDraftCount = 0;

      for (final row in preview.rows) {
        if (!row.isValid || row.price == null) {
          continue;
        }

        var categoryId = row.categoryId;
        var status = row.status;

        if (row.hasMissingCategory) {
          switch (strategy) {
            case _MissingCategoryImportStrategy.createCategories:
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
            case _MissingCategoryImportStrategy.importAsDraftUncategorized:
              categoryId = null;
              status = 'draft';
              uncategorizedDraftCount += 1;
              break;
            case _MissingCategoryImportStrategy.skipRows:
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

      await _loadData();
      if (!mounted) return;

      setState(() {
        _importPreview = null;
      });

      AppSnackBar.show(
        context: context,
        text: importedCount == 0
            ? 'No products were imported from ${preview.fileName}.'
            : 'Imported $importedCount product${importedCount == 1 ? '' : 's'} from ${preview.fileName}${uncategorizedDraftCount > 0 ? ', moved $uncategorizedDraftCount row${uncategorizedDraftCount == 1 ? '' : 's'} to draft review' : ''}${skippedCount > 0 ? ', skipped $skippedCount row${skippedCount == 1 ? '' : 's'}' : ''}.',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _clearImportPreview() {
    setState(() {
      _importPreview = null;
      _importedFileName = null;
    });
  }

  void _toggleProductSelection(String productId, bool selected) {
    setState(() {
      if (selected) {
        _selectedProductIds.add(productId);
      } else {
        _selectedProductIds.remove(productId);
      }
    });
  }

  void _toggleSelectAllFiltered(bool selected) {
    setState(() {
      final visibleIds = _filteredProducts.map((product) => product.id);
      if (selected) {
        _selectedProductIds.addAll(visibleIds);
      } else {
        _selectedProductIds.removeWhere(
          (id) => _filteredProducts.any((product) => product.id == id),
        );
      }
    });
  }

  void _clearSelectedProducts() {
    setState(_selectedProductIds.clear);
  }

  Future<void> _bulkUpdateSelectedProducts({
    String? status,
    bool? featured,
    required String successMessage,
  }) async {
    if (_selectedProductIds.isEmpty || _isBulkUpdating) {
      return;
    }

    setState(() => _isBulkUpdating = true);
    try {
      await _productService.bulkUpdateProducts(
        ids: _selectedProductIds.toList(),
        status: status,
        featured: featured,
      );
      await _loadData();
      if (!mounted) return;
      _clearSelectedProducts();
      AppSnackBar.show(
        context: context,
        text: successMessage,
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isBulkUpdating = false);
      }
    }
  }

  Future<void> _deleteSelectedProducts() async {
    if (_selectedProductIds.isEmpty || _isBulkUpdating) return;

    final count = _selectedProductIds.length;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected products'),
        content: Text(
          'Delete $count selected product${count == 1 ? '' : 's'} permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _isBulkUpdating = true);
    try {
      await _productService.deleteProducts(_selectedProductIds.toList());
      await _loadData();
      if (!mounted) return;
      _clearSelectedProducts();
      AppSnackBar.show(
        context: context,
        text: 'Deleted $count selected product${count == 1 ? '' : 's'}.',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isBulkUpdating = false);
      }
    }
  }

  Future<void> _downloadAllProducts() async {
    if (_products.isEmpty || _isExporting) {
      return;
    }

    setState(() => _isExporting = true);

    try {
      final categoryNamesById = {
        for (final category in _categories) category.id: category.name,
      };
      final workbook = excel.Excel.createExcel();
      final sheet = workbook['Products'];
      if (workbook.getDefaultSheet() != 'Products') {
        final defaultSheet = workbook.getDefaultSheet();
        if (defaultSheet != null && defaultSheet != 'Products') {
          workbook.delete(defaultSheet);
        }
      }

      sheet.appendRow(_excelHeaderRow);
      for (final product in _products) {
        sheet.appendRow([
          excel.TextCellValue(product.id),
          excel.TextCellValue(product.sku ?? ''),
          excel.TextCellValue(product.name),
          excel.TextCellValue(product.title),
          excel.TextCellValue(product.description),
          excel.TextCellValue(categoryNamesById[product.categoryId] ?? ''),
          excel.TextCellValue(product.categoryId ?? ''),
          excel.DoubleCellValue(product.price),
          if (product.salePrice != null)
            excel.DoubleCellValue(product.salePrice!)
          else
            excel.TextCellValue(''),
          excel.DoubleCellValue(product.rating),
          excel.IntCellValue(product.stockQuantity),
          excel.IntCellValue(product.lowStockThreshold),
          excel.TextCellValue(product.status),
          excel.BoolCellValue(product.featured),
          excel.TextCellValue(product.sizes.join('|')),
          excel.TextCellValue(product.mainImageUrl ?? ''),
          excel.TextCellValue(product.imageUrls.join('|')),
        ]);
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'products_export_$timestamp.xlsx';

      if (kIsWeb) {
        final savedBytes = workbook.save(fileName: fileName);
        if (savedBytes == null) {
          throw 'Could not generate the Excel file.';
        }
      } else {
        final fileBytes = workbook.save();
        if (fileBytes == null || fileBytes.isEmpty) {
          throw 'Could not generate the Excel file.';
        }

        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Download all products',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const ['xlsx'],
        );

        if (savePath == null) {
          return;
        }

        final outputFile = File(savePath);
        await outputFile.writeAsBytes(fileBytes, flush: true);
      }

      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text:
            'Downloaded ${_products.length} product${_products.length == 1 ? '' : 's'} as Excel.',
        icon: Icons.download_done_rounded,
        backgroundColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final regularPrice = _parseOptionalDouble(_priceController.text);
    final currentPrice = _parseOptionalDouble(_salePriceController.text);
    final rating = double.tryParse(_ratingController.text.trim()) ?? 0;
    final stockQuantity = int.tryParse(_stockController.text.trim()) ?? 0;
    final lowStockThreshold =
        int.tryParse(_lowStockController.text.trim()) ?? 5;

    if (currentPrice == null) {
      AppSnackBar.show(
        context: context,
        text: 'Please enter the current selling price.',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
      return;
    }

    if (regularPrice != null && currentPrice >= regularPrice) {
      AppSnackBar.show(
        context: context,
        text: 'Current price must be lower than the original price.',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? mainImageUrl = _mainImageUrlController.text.trim().isEmpty
          ? _editingProduct?.mainImageUrl
          : _mainImageUrlController.text.trim();

      if (_selectedImage != null) {
        if (_selectedImageBytes != null) {
          mainImageUrl = await _productService.uploadProductImageBytes(
            bytes: _selectedImageBytes!,
            fileName: _selectedImage!.name,
            mimeType: _selectedImage!.mimeType,
          );
        } else {
          mainImageUrl = await _productService.uploadProductImage(
            _selectedImage!,
          );
        }
      }

      if (!mounted) return;

      final uploadedGalleryUrls = <String>[];
      for (var i = 0; i < _selectedGalleryImages.length; i++) {
        final galleryImage = _selectedGalleryImages[i];
        final galleryImageBytes = _selectedGalleryImageBytes[i];
        final uploadedUrl = await _productService.uploadProductImageBytes(
          bytes: galleryImageBytes,
          fileName: galleryImage.name,
          mimeType: galleryImage.mimeType,
        );
        uploadedGalleryUrls.add(uploadedUrl);
      }

      final normalizedGalleryUrls = [
        ..._galleryImageUrls,
        ...uploadedGalleryUrls,
      ].where((url) => url.trim().isNotEmpty).toSet().toList();

      final storedPrice = regularPrice ?? currentPrice;
      final storedSalePrice = regularPrice == null ? null : currentPrice;

      final payload = (
        name: _nameController.text,
        title: _titleController.text,
        description: _descriptionController.text,
        price: storedPrice,
        salePrice: storedSalePrice,
        rating: rating,
        sizes: _parseSizes(_sizesController.text),
        categoryId: _selectedCategoryId,
        stockQuantity: stockQuantity,
        lowStockThreshold: lowStockThreshold,
        status: _selectedStatus,
        featured: _isFeatured,
        mainImageUrl: mainImageUrl,
        imageUrls: normalizedGalleryUrls,
        sku: _skuController.text.trim(),
      );

      final wasEditing = _editingProduct != null;
      if (_editingProduct == null) {
        await _productService.createProduct(
          name: payload.name,
          title: payload.title,
          description: payload.description,
          price: payload.price,
          salePrice: payload.salePrice,
          rating: payload.rating,
          sizes: payload.sizes,
          categoryId: payload.categoryId,
          stockQuantity: payload.stockQuantity,
          lowStockThreshold: payload.lowStockThreshold,
          status: payload.status,
          featured: payload.featured,
          mainImageUrl: payload.mainImageUrl,
          imageUrls: payload.imageUrls,
          sku: payload.sku,
        );
      } else {
        await _productService.updateProduct(
          id: _editingProduct!.id,
          name: payload.name,
          title: payload.title,
          description: payload.description,
          price: payload.price,
          salePrice: payload.salePrice,
          rating: payload.rating,
          sizes: payload.sizes,
          categoryId: payload.categoryId,
          stockQuantity: payload.stockQuantity,
          lowStockThreshold: payload.lowStockThreshold,
          status: payload.status,
          featured: payload.featured,
          mainImageUrl: payload.mainImageUrl,
          imageUrls: payload.imageUrls,
          sku: payload.sku,
        );
      }

      await _loadData();
      _resetForm();

      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: wasEditing
            ? 'Product updated successfully.'
            : 'Product created successfully.',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Delete "${product.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _isDeleting = true);

    try {
      await _productService.deleteProduct(product.id);
      await _loadData();
      if (!mounted) return;
      if (_editingProduct?.id == product.id) {
        _resetForm();
      }
      AppSnackBar.show(
        context: context,
        text: 'Product deleted successfully.',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _startEditing(ProductModel product) {
    _nameController.text = product.name;
    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _priceController.text = product.hasSale ? product.price.toString() : '';
    _salePriceController.text = product.effectivePrice.toString();
    _ratingController.text = product.rating.toString();
    _sizesController.text = product.sizes.join(',');
    _stockController.text = product.stockQuantity.toString();
    _lowStockController.text = product.lowStockThreshold.toString();
    _skuController.text = product.sku ?? '';
    _mainImageUrlController.text = product.mainImageUrl ?? '';

    setState(() {
      _editingProduct = product;
      _selectedCategoryId = product.categoryId;
      _selectedStatus = product.status;
      _isFeatured = product.featured;
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedGalleryImages.clear();
      _selectedGalleryImageBytes.clear();
      _galleryImageUrls
        ..clear()
        ..addAll(product.imageUrls);
    });
  }

  void _resetForm() {
    _nameController.clear();
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _salePriceController.clear();
    _ratingController.text = '4.5';
    _sizesController.text = '38,39,40,41';
    _stockController.text = '0';
    _lowStockController.text = '5';
    _skuController.clear();
    _mainImageUrlController.clear();

    setState(() {
      _editingProduct = null;
      _selectedCategoryId = null;
      _selectedStatus = 'active';
      _isFeatured = false;
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedGalleryImages.clear();
      _selectedGalleryImageBytes.clear();
      _galleryImageUrls.clear();
    });
  }

  List<ProductModel> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();

    return _products.where((product) {
      final matchesCategory =
          _categoryFilter == null || product.categoryId == _categoryFilter;
      if (!matchesCategory) {
        return false;
      }

      if (query.isEmpty) return true;

      final haystack = [
        product.name,
        product.title,
        product.description,
        product.sku ?? '',
        product.status,
        product.price.toString(),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  bool get _allFilteredSelected =>
      _filteredProducts.isNotEmpty &&
      _filteredProducts.every((product) => _selectedProductIds.contains(product.id));

  String _categoryName(String? categoryId) {
    if (categoryId == null) return 'Uncategorized';

    for (final category in _categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'Uncategorized';
  }

  List<int> _parseSizes(String rawValue) {
    return rawValue
        .split(RegExp(r'[, ]+'))
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .toList();
  }

  double? _parseOptionalDouble(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          color: AppColors.redColor,
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
            children: [
              AdminResponsiveSplit(
                breakpoint: 1140,
                spacing: 20,
                primaryFlex: 5,
                secondaryFlex: 6,
                primary: _buildComposerCard(),
                secondary: _buildLibraryCard(constraints.maxWidth >= 900),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComposerCard() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionIntro(
            title: _editingProduct == null ? 'Create Product' : 'Edit Product',
            subtitle:
                'Manage core catalog details, current pricing, inventory, status, and uploaded imagery from one admin form.',
          ),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Product name',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _titleController,
                  label: 'Short title',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                _buildNumberRow(),
                const SizedBox(height: 14),
                _buildInventoryRow(),
                const SizedBox(height: 14),
                _buildTextField(controller: _skuController, label: 'SKU'),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _sizesController,
                  label: 'Sizes',
                  hintText: '38,39,40,41',
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: _inputDecoration('Category'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Uncategorized'),
                    ),
                    ..._categories.map(
                      (category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: _inputDecoration('Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isFeatured,
                  onChanged: (value) => setState(() => _isFeatured = value),
                  title: const Text('Featured product'),
                  subtitle: const Text(
                    'Highlight this product in curated storefront sections.',
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _mainImageUrlController,
                  label: 'Main image URL',
                  hintText: 'Optional fallback URL',
                ),
                const SizedBox(height: 14),
                _ProductImageUploadCard(
                  bytes: _selectedImageBytes,
                  fileName:
                      _selectedImage?.name ?? _editingProduct?.mainImageUrl,
                  isPickingImage: _isPickingImage,
                  onPickImage: _pickImage,
                  title: 'Upload main product image',
                  description:
                      'Use upload for the hero image, or keep a direct image URL above as a fallback.',
                  onRemoveImage: () {
                    setState(() {
                      _selectedImage = null;
                      _selectedImageBytes = null;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _ProductGalleryUploadCard(
                  existingUrls: _galleryImageUrls,
                  selectedBytes: _selectedGalleryImageBytes,
                  selectedNames: _selectedGalleryImages
                      .map((image) => image.name)
                      .toList(growable: false),
                  isPickingImages: _isPickingImage,
                  onPickImages: _pickGalleryImages,
                  onRemoveExisting: (index) {
                    setState(() => _galleryImageUrls.removeAt(index));
                  },
                  onRemoveSelected: (index) {
                    setState(() {
                      _selectedGalleryImages.removeAt(index);
                      _selectedGalleryImageBytes.removeAt(index);
                    });
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 4,
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: (_isSaving || _isDeleting)
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.redColor,
                              ),
                            )
                          : FilledButton(
                              onPressed: _saveProduct,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.redColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _editingProduct == null
                                    ? 'Create Product'
                                    : 'Save Changes',
                              ),
                            ),
                    ),
                    if (_editingProduct != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryCard(bool isWide) {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionIntro(
            title: 'Product Library',
            subtitle:
                'Search products, filter by category, and keep the catalog organized with fast edit and delete actions.',
            trailing: SizedBox(
              width: 230,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search products',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.primaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildImportSection(),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _categoryFilter,
            decoration: _inputDecoration('Filter by category'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All categories'),
              ),
              ..._categories.map(
                (category) => DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _categoryFilter = value),
          ),
          const SizedBox(height: 14),
          if (_filteredProducts.isNotEmpty) ...[
            _buildBulkActionBar(),
            const SizedBox(height: 14),
          ],
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppColors.redColor),
              ),
            )
          else if (_filteredProducts.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.inventory_2_outlined,
              title: 'No products found',
              description:
                  'Create your first product or adjust the current search and filter settings.',
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _filteredProducts.map((product) {
                return SizedBox(
                  width: isWide ? 300 : double.infinity,
                  child: _ProductCard(
                    product: product,
                    categoryName: _categoryName(product.categoryId),
                    isSelected: _selectedProductIds.contains(product.id),
                    onSelectionChanged: (value) =>
                        _toggleProductSelection(product.id, value),
                    onEdit: () => _startEditing(product),
                    onDelete: () => _deleteProduct(product),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildImportSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Import or download products',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isExporting || _products.isEmpty
                    ? null
                    : _downloadAllProducts,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: Colors.black12),
                ),
                icon: _isExporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  _isExporting ? 'Preparing...' : 'Download all',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a CSV or XLSX sheet, or export the full catalog to Excel. Imports are audited before saving so missing categories and invalid rows can be reviewed safely.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 10),
          if (_importedFileName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AdminTag(
                label: _importedFileName!,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.blackColor,
                isCompact: true,
              ),
            ),
          if (_importPreview != null) ...[
            _ProductImportPreviewCard(
              preview: _importPreview!,
              isBusy: _isImporting,
              onCreateCategories: () => _confirmSheetImport(
                _MissingCategoryImportStrategy.createCategories,
              ),
              onImportAsDraft: () => _confirmSheetImport(
                _MissingCategoryImportStrategy.importAsDraftUncategorized,
              ),
              onSkipRows: () =>
                  _confirmSheetImport(_MissingCategoryImportStrategy.skipRows),
              onCancel: _clearImportPreview,
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isImporting ? null : _pickImportSheet,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blackColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _isImporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(
                _isImporting
                    ? 'Preparing import...'
                    : _importPreview != null
                    ? 'Choose another CSV / XLSX sheet'
                    : 'Upload CSV / XLSX sheet',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar() {
    final selectedCount = _selectedProductIds.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _allFilteredSelected,
                onChanged: _isBulkUpdating
                    ? null
                    : (value) => _toggleSelectAllFiltered(value ?? false),
              ),
              Expanded(
                child: Text(
                  selectedCount == 0
                      ? 'Select products to run bulk actions.'
                      : '$selectedCount product${selectedCount == 1 ? '' : 's'} selected.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blackColor,
                  ),
                ),
              ),
              if (selectedCount > 0)
                TextButton(
                  onPressed: _isBulkUpdating ? null : _clearSelectedProducts,
                  child: const Text('Clear'),
                ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: selectedCount == 0 || _isBulkUpdating
                    ? null
                    : () => _bulkUpdateSelectedProducts(
                          status: 'active',
                          successMessage:
                              'Selected products are now active.',
                        ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Activate'),
              ),
              OutlinedButton.icon(
                onPressed: selectedCount == 0 || _isBulkUpdating
                    ? null
                    : () => _bulkUpdateSelectedProducts(
                          status: 'hidden',
                          successMessage:
                              'Selected products are now hidden.',
                        ),
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: const Text('Hide'),
              ),
              OutlinedButton.icon(
                onPressed: selectedCount == 0 || _isBulkUpdating
                    ? null
                    : () => _bulkUpdateSelectedProducts(
                          featured: true,
                          successMessage:
                              'Selected products are now featured.',
                        ),
                icon: const Icon(Icons.star_outline_rounded, size: 18),
                label: const Text('Feature'),
              ),
              OutlinedButton.icon(
                onPressed: selectedCount == 0 || _isBulkUpdating
                    ? null
                    : () => _bulkUpdateSelectedProducts(
                          featured: false,
                          successMessage:
                              'Selected products were removed from featured.',
                        ),
                icon: const Icon(Icons.star_border_rounded, size: 18),
                label: const Text('Unfeature'),
              ),
              OutlinedButton.icon(
                onPressed: selectedCount == 0 || _isBulkUpdating
                    ? null
                    : _deleteSelectedProducts,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                icon: _isBulkUpdating
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _priceController,
            label: 'Original price',
            hintText: 'Optional',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _salePriceController,
            label: 'Current price',
            hintText: 'Required',
            validator: _requiredValidator,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _ratingController,
            label: 'Rating',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _stockController,
            label: 'Stock quantity',
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _lowStockController,
            label: 'Low stock threshold',
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _inputDecoration(label, hintText: hintText),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: AppColors.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.redColor, width: 1.4),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}

class _ProductImageUploadCard extends StatelessWidget {
  const _ProductImageUploadCard({
    required this.bytes,
    required this.fileName,
    required this.isPickingImage,
    required this.title,
    required this.description,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final Uint8List? bytes;
  final String? fileName;
  final bool isPickingImage;
  final String title;
  final String description;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grayColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.white,
                child: hasImage
                    ? Image.memory(bytes!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 42,
                            color: AppColors.redColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.blackColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.hintColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasImage
                      ? (fileName ?? 'Selected image')
                      : 'No image selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.hintColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (hasImage)
                TextButton(
                  onPressed: onRemoveImage,
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      color: AppColors.redColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: isPickingImage ? null : onPickImage,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blackColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isPickingImage
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(hasImage ? 'Change' : 'Choose Image'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductGalleryUploadCard extends StatelessWidget {
  const _ProductGalleryUploadCard({
    required this.existingUrls,
    required this.selectedBytes,
    required this.selectedNames,
    required this.isPickingImages,
    required this.onPickImages,
    required this.onRemoveExisting,
    required this.onRemoveSelected,
  });

  final List<String> existingUrls;
  final List<Uint8List> selectedBytes;
  final List<String> selectedNames;
  final bool isPickingImages;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    final hasImages = existingUrls.isNotEmpty || selectedBytes.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grayColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gallery images',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload multiple detail shots instead of pasting raw gallery URLs.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 14),
          if (hasImages)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < existingUrls.length; i++)
                  _GalleryImageChip(
                    label: 'Saved image ${i + 1}',
                    image: Image.network(
                      existingUrls[i],
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.grayColor,
                        ),
                      ),
                    ),
                    onRemove: () => onRemoveExisting(i),
                  ),
                for (var i = 0; i < selectedBytes.length; i++)
                  _GalleryImageChip(
                    label: selectedNames[i],
                    image: Image.memory(selectedBytes[i], fit: BoxFit.cover),
                    onRemove: () => onRemoveSelected(i),
                  ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'No gallery images selected yet.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.hintColor,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isPickingImages ? null : onPickImages,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blackColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: isPickingImages
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.collections_outlined),
              label: const Text('Upload Gallery Images'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryImageChip extends StatelessWidget {
  const _GalleryImageChip({
    required this.label,
    required this.image,
    required this.onRemove,
  });

  final String label;
  final Widget image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 92,
              width: 118,
              child: image,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.hintColor,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRemove,
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: AppColors.redColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductModel product;
  final String categoryName;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.7,
                  child: Image.network(
                    product.primaryImage,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryColor,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.grayColor,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    child: Checkbox(
                      value: isSelected,
                      visualDensity: VisualDensity.compact,
                      onChanged: (value) => onSelectionChanged(value ?? false),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminTag(label: categoryName, isCompact: true),
                    AdminTag(label: product.status, isCompact: true),
                    AdminTag(
                      label: product.isInStock
                          ? '${product.stockQuantity} in stock'
                          : 'Out of stock',
                      backgroundColor: product.isInStock
                          ? const Color(0xFFE8F7ED)
                          : const Color(0xFFFFE4E6),
                      foregroundColor: product.isInStock
                          ? const Color(0xFF1E8E5A)
                          : Colors.red,
                      isCompact: true,
                    ),
                    if (product.featured)
                      const AdminTag(
                        label: 'Featured',
                        backgroundColor: Color(0xFFE7F0FF),
                        foregroundColor: Color(0xFF2558C5),
                        isCompact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${product.effectivePrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.blackColor,
                            ),
                          ),
                          if (product.hasSale)
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.hintColor,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 19),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      color: Colors.red,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 19),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _MissingCategoryImportStrategy {
  createCategories,
  importAsDraftUncategorized,
  skipRows,
}

class _ProductImportPreview {
  const _ProductImportPreview({
    required this.fileName,
    required this.rows,
    required this.invalidRowCount,
  });

  final String fileName;
  final List<AdminProductImportRow> rows;
  final int invalidRowCount;

  int get totalRowCount => rows.length;

  int get readyToImportCount =>
      rows.where((row) => row.isValid && !row.hasMissingCategory).length;

  int get rowsWithMissingCategoriesCount =>
      rows.where((row) => row.isValid && row.hasMissingCategory).length;

  List<String> get missingCategoryLabels {
    final labels = <String>{};
    for (final row in rows) {
      if (row.isValid && row.hasMissingCategory) {
        labels.add(row.missingCategoryLabel);
      }
    }
    final sorted = labels.toList()..sort();
    return sorted;
  }
}

class _ProductImportPreviewCard extends StatelessWidget {
  const _ProductImportPreviewCard({
    required this.preview,
    required this.isBusy,
    required this.onCreateCategories,
    required this.onImportAsDraft,
    required this.onSkipRows,
    required this.onCancel,
  });

  final _ProductImportPreview preview;
  final bool isBusy;
  final VoidCallback onCreateCategories;
  final VoidCallback onImportAsDraft;
  final VoidCallback onSkipRows;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sheet audit',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Checked ${preview.totalRowCount} row${preview.totalRowCount == 1 ? '' : 's'}. ${preview.readyToImportCount} ${preview.readyToImportCount == 1 ? 'row is' : 'rows are'} ready now, ${preview.rowsWithMissingCategoriesCount} ${preview.rowsWithMissingCategoriesCount == 1 ? 'row has' : 'rows have'} missing categories, and ${preview.invalidRowCount} ${preview.invalidRowCount == 1 ? 'row is' : 'rows are'} invalid.',
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          if (preview.missingCategoryLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Missing categories: ${preview.missingCategoryLabels.join(', ')}',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: isBusy ? null : onCreateCategories,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blackColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Create missing categories'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onImportAsDraft,
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Import missing as draft'),
              ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onSkipRows,
                icon: const Icon(Icons.skip_next_outlined),
                label: const Text('Skip missing rows'),
              ),
              TextButton.icon(
                onPressed: isBusy ? null : onCancel,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel review'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
