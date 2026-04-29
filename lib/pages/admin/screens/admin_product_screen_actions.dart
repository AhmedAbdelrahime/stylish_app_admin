// ignore_for_file: invalid_use_of_protected_member

part of 'admin_product_screen.dart';

extension _AdminProductViewActions on _AdminProductViewState {
  Future<void> _loadData() async {
    try {
      await context.read<AdminProductCubit>().loadData();
    } catch (error) {
      if (!mounted) return;
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
    final productCubit = context.read<AdminProductCubit>();
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
        categories: productCubit.state.categories,
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
    AdminMissingCategoryImportStrategy strategy,
  ) async {
    final preview = _importPreview;
    if (preview == null || _isImporting) return;
    setState(() => _isImporting = true);
    try {
      final result = await context.read<AdminProductCubit>().importRows(
        rows: preview.rows,
        invalidRowCount: preview.invalidRowCount,
        strategy: strategy,
      );
      if (!mounted) return;
      setState(() {
        _importPreview = null;
      });
      AppSnackBar.show(
        context: context,
        text: result.importedCount == 0
            ? 'No products were imported from ${preview.fileName}.'
            : 'Imported ${result.importedCount} product${result.importedCount == 1 ? '' : 's'} from ${preview.fileName}${result.uncategorizedDraftCount > 0 ? ', moved ${result.uncategorizedDraftCount} row${result.uncategorizedDraftCount == 1 ? '' : 's'} to draft review' : ''}${result.skippedCount > 0 ? ', skipped ${result.skippedCount} row${result.skippedCount == 1 ? '' : 's'}' : ''}.',
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
    context.read<AdminProductCubit>().toggleProductSelection(
      productId,
      selected,
    );
  }

  void _toggleSelectAllFiltered(
    List<ProductModel> filteredProducts,
    bool selected,
  ) {
    context.read<AdminProductCubit>().toggleVisibleProductSelection(
      productIds: filteredProducts.map((product) => product.id),
      selected: selected,
    );
  }

  void _clearSelectedProducts() {
    context.read<AdminProductCubit>().clearSelectedProducts();
  }

  Future<void> _bulkUpdateSelectedProducts({
    String? status,
    bool? featured,
    required String successMessage,
  }) async {
    final productState = context.read<AdminProductCubit>().state;
    if (productState.selectedProductIds.isEmpty ||
        productState.isBulkUpdating) {
      return;
    }
    try {
      await context.read<AdminProductCubit>().bulkUpdateSelectedProducts(
        status: status,
        featured: featured,
      );
      if (!mounted) return;
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
    }
  }

  Future<void> _deleteSelectedProducts() async {
    final productCubit = context.read<AdminProductCubit>();
    final productState = productCubit.state;
    if (productState.selectedProductIds.isEmpty ||
        productState.isBulkUpdating) {
      return;
    }
    final count = productState.selectedProductIds.length;
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
    try {
      await productCubit.deleteSelectedProducts();
      if (!mounted) return;
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
    }
  }

  Future<void> _downloadAllProducts() async {
    final productState = context.read<AdminProductCubit>().state;
    if (productState.products.isEmpty || _isExporting) {
      return;
    }
    setState(() => _isExporting = true);
    try {
      final categoryNamesById = {
        for (final category in productState.categories)
          category.id: category.name,
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
      for (final product in productState.products) {
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
            'Downloaded ${productState.products.length} product${productState.products.length == 1 ? '' : 's'} as Excel.',
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
    try {
      final storedPrice = regularPrice ?? currentPrice;
      final storedSalePrice = regularPrice == null ? null : currentPrice;
      final wasEditing = _editingProduct != null;
      await context.read<AdminProductCubit>().saveProduct(
        AdminProductSaveInput(
          editingProduct: _editingProduct,
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
          mainImageUrl: _mainImageUrlController.text,
          selectedImage: _selectedImage,
          selectedImageBytes: _selectedImageBytes,
          existingGalleryUrls: List<String>.of(_galleryImageUrls),
          selectedGalleryImages: List<XFile>.of(_selectedGalleryImages),
          selectedGalleryImageBytes: List<Uint8List>.of(
            _selectedGalleryImageBytes,
          ),
          sku: _skuController.text.trim(),
        ),
      );
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
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final productCubit = context.read<AdminProductCubit>();
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
    try {
      await productCubit.deleteProduct(product);
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

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    final query = _searchQuery.trim().toLowerCase();
    return products.where((product) {
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

  bool _allFilteredSelected(
    List<ProductModel> filteredProducts,
    Set<String> selectedProductIds,
  ) =>
      filteredProducts.isNotEmpty &&
      filteredProducts.every(
        (product) => selectedProductIds.contains(product.id),
      );
  String _categoryName(List<CategoryModel> categories, String? categoryId) {
    if (categoryId == null) return 'Uncategorized';
    for (final category in categories) {
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
}
