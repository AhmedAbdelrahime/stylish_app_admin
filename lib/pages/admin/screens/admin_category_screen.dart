import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/home/data/category_service.dart';
import 'package:hungry/pages/home/data/product_service.dart';
import 'package:hungry/pages/home/models/category_model.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:image_picker/image_picker.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  static const _categoryRequestTimeout = Duration(seconds: 20);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _sortOrderController = TextEditingController(
    text: '0',
  );
  final TextEditingController _searchController = TextEditingController();
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false;
  bool _isDeleting = false;
  bool _isVisible = true;
  List<CategoryModel> _categories = const [];
  List<ProductModel> _products = const [];
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String _searchQuery = '';
  String? _saveStatusMessage;
  CategoryModel? _editingCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _sortOrderController.dispose();
    _searchController.dispose();
    super.dispose();
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
        text: 'Failed to pick image. Please try again.',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    debugPrint('[AdminCategory] _loadCategories:start');
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _categoryService.getCategories(),
        _productService.getAllProducts(),
      ]).timeout(
        _categoryRequestTimeout,
        onTimeout: () => throw 'Loading categories took too long. Please try again.',
      );

      final categories = results[0] as List<CategoryModel>;
      final products = results[1] as List<ProductModel>;
      debugPrint(
        '[AdminCategory] _loadCategories:success categories=${categories.length} products=${products.length}',
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _products = products;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[AdminCategory] _loadCategories:error $error');
      debugPrintStack(
        label: '[AdminCategory] _loadCategories:stack',
        stackTrace: stackTrace,
      );
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

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('[AdminCategory] _saveCategory:validation_failed');
      return;
    }
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    final isEditing = _editingCategory != null;
    debugPrint(
      '[AdminCategory] _saveCategory:start isEditing=$isEditing name="${_nameController.text.trim()}" sortOrder=$sortOrder visible=$_isVisible hasSelectedImage=${_selectedImage != null}',
    );
    setState(() {
      _isSaving = true;
      _saveStatusMessage = 'Preparing category save...';
    });

    try {
      setState(() {
        _saveStatusMessage = _selectedImage != null
            ? 'Uploading category image...'
            : 'Checking category image source...';
      });
      debugPrint('[AdminCategory] _saveCategory:image_step:start');
      final currentImageUrl = _selectedImage != null
          ? await _uploadSelectedCategoryImage()
          : _normalizedImageUrl(
                _imageUrlController.text,
              ) ??
              _editingCategory?.imageUrl;
      debugPrint(
        '[AdminCategory] _saveCategory:image_step:done imageUrl=$currentImageUrl',
      );

      if (!mounted) return;

      if (currentImageUrl == null || currentImageUrl.trim().isEmpty) {
        debugPrint('[AdminCategory] _saveCategory:image_missing');
        AppSnackBar.show(
          context: context,
          text: 'Please upload a category image or paste an image URL before saving.',
          icon: Icons.image_not_supported_outlined,
          backgroundColor: Colors.red,
        );
        return;
      }

      if (!isEditing) {
        setState(() {
          _saveStatusMessage = 'Creating category record...';
        });
        debugPrint('[AdminCategory] _saveCategory:create:start');
        await _categoryService
            .createCategory(
              name: _nameController.text.trim(),
              imageUrl: currentImageUrl,
              isVisible: _isVisible,
              sortOrder: sortOrder,
            )
            .timeout(
              _categoryRequestTimeout,
              onTimeout: () => throw 'Saving the category took too long. Please try again.',
            );
        debugPrint('[AdminCategory] _saveCategory:create:done');
      } else {
        setState(() {
          _saveStatusMessage = 'Updating category record...';
        });
        debugPrint('[AdminCategory] _saveCategory:update:start id=${_editingCategory!.id}');
        await _categoryService
            .updateCategory(
              id: _editingCategory!.id,
              name: _nameController.text.trim(),
              imageUrl: currentImageUrl,
              isVisible: _isVisible,
              sortOrder: sortOrder,
            )
            .timeout(
              _categoryRequestTimeout,
              onTimeout: () => throw 'Updating the category took too long. Please try again.',
            );
        debugPrint('[AdminCategory] _saveCategory:update:done');
      }

      debugPrint('[AdminCategory] _saveCategory:reload:start');
      setState(() {
        _saveStatusMessage = 'Refreshing category list...';
      });
      await _loadCategories().timeout(
        _categoryRequestTimeout,
        onTimeout: () => throw 'Refreshing categories took too long after save.',
      );
      debugPrint('[AdminCategory] _saveCategory:reload:done');
      _resetForm();

      if (!mounted) return;

      AppSnackBar.show(
        context: context,
        text: isEditing
            ? 'Category updated successfully.'
            : 'Category added successfully.',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (error, stackTrace) {
      debugPrint('[AdminCategory] _saveCategory:error $error');
      debugPrintStack(
        label: '[AdminCategory] _saveCategory:stack',
        stackTrace: stackTrace,
      );
      if (!mounted) return;

      AppSnackBar.show(
        context: context,
        text: SupabaseErrorMapper.map(error),
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      debugPrint('[AdminCategory] _saveCategory:finally mounted=$mounted');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveStatusMessage = null;
        });
      }
    }
  }

  Future<String> _uploadSelectedCategoryImage() async {
    final selectedImage = _selectedImage;
    final selectedImageBytes = _selectedImageBytes;
    if (selectedImage == null) {
      throw 'No category image is selected.';
    }

    if (selectedImageBytes != null) {
      debugPrint(
        '[AdminCategory] _uploadSelectedCategoryImage:using_cached_bytes bytes=${selectedImageBytes.length}',
      );
      return _categoryService
          .uploadCategoryImageBytes(
            bytes: selectedImageBytes,
            fileName: selectedImage.name,
            mimeType: selectedImage.mimeType,
          )
          .timeout(
            _categoryRequestTimeout,
            onTimeout: () => throw 'Image upload took too long. Please check your connection and storage setup.',
          );
    }

    debugPrint('[AdminCategory] _uploadSelectedCategoryImage:using_file_read');
    return _categoryService
        .uploadCategoryImage(selectedImage)
        .timeout(
          _categoryRequestTimeout,
          onTimeout: () => throw 'Image upload took too long. Please check your connection and storage setup.',
        );
  }

  void _startEditing(CategoryModel category) {
    _nameController.text = category.name;
    _imageUrlController.text = category.imageUrl ?? '';
    _sortOrderController.text = category.sortOrder.toString();
    setState(() {
      _editingCategory = category;
      _selectedImage = null;
      _selectedImageBytes = null;
      _isVisible = category.isVisible;
    });
  }

  void _resetForm() {
    _nameController.clear();
    _imageUrlController.clear();
    _sortOrderController.text = '0';
    setState(() {
      _editingCategory = null;
      _selectedImage = null;
      _selectedImageBytes = null;
      _isVisible = true;
    });
  }

  Future<void> _toggleCategoryVisibility(CategoryModel category) async {
    setState(() => _isSaving = true);
    try {
      await _categoryService.updateCategoryVisibility(
        id: category.id,
        isVisible: !category.isVisible,
      );
      await _loadCategories();
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: category.isVisible
            ? '${category.name} is now hidden.'
            : '${category.name} is now visible.',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (error, stackTrace) {
      debugPrint('[AdminCategory] _toggleCategoryVisibility:error $error');
      debugPrintStack(
        label: '[AdminCategory] _toggleCategoryVisibility:stack',
        stackTrace: stackTrace,
      );
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

  Future<void> _moveCategorySort(CategoryModel category, int delta) async {
    final orderedCategories = [..._categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final currentIndex = orderedCategories.indexWhere(
      (item) => item.id == category.id,
    );
    if (currentIndex == -1) {
      return;
    }

    final targetIndex = currentIndex + delta;
    if (targetIndex < 0 || targetIndex >= orderedCategories.length) {
      AppSnackBar.show(
        context: context,
        text: delta < 0
            ? '${category.name} is already at the top.'
            : '${category.name} is already at the bottom.',
        icon: Icons.info_outline_rounded,
        backgroundColor: AppColors.blackColor,
      );
      return;
    }

    final reordered = [...orderedCategories];
    final movedCategory = reordered.removeAt(currentIndex);
    reordered.insert(targetIndex, movedCategory);

    setState(() => _isSaving = true);
    try {
      await _categoryService.reorderCategories(reordered);
      await _loadCategories();
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: delta < 0
            ? '${category.name} moved up.'
            : '${category.name} moved down.',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (error, stackTrace) {
      debugPrint('[AdminCategory] _moveCategorySort:error $error');
      debugPrintStack(
        label: '[AdminCategory] _moveCategorySort:stack',
        stackTrace: stackTrace,
      );
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

  Future<void> _deleteCategory(CategoryModel category) async {
    final linkedProductsCount = _products
        .where((product) => product.categoryId == category.id)
        .length;

    if (linkedProductsCount > 0) {
      AppSnackBar.show(
        context: context,
        text:
            'Cannot delete ${category.name}. It still has $linkedProductsCount linked product${linkedProductsCount == 1 ? '' : 's'}.',
        icon: Icons.warning_amber_rounded,
        backgroundColor: Colors.red,
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Delete "${category.name}" permanently?'),
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
      await _categoryService.deleteCategory(category.id);
      await _loadCategories();

      if (!mounted) return;
      if (_editingCategory?.id == category.id) {
        _resetForm();
      }

      AppSnackBar.show(
        context: context,
        text: 'Category deleted successfully.',
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green,
      );
    } catch (error, stackTrace) {
      debugPrint('[AdminCategory] _deleteCategory:error $error');
      debugPrintStack(
        label: '[AdminCategory] _deleteCategory:stack',
        stackTrace: stackTrace,
      );
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

  List<CategoryModel> get _filteredCategories {
    if (_searchQuery.trim().isEmpty) {
      return _categories;
    }

    final query = _searchQuery.trim().toLowerCase();
    return _categories.where((category) {
      return category.name.toLowerCase().contains(query) ||
          category.id.toLowerCase().contains(query);
    }).toList();
  }

  int _linkedProductsCount(String categoryId) {
    return _products
        .where((product) => product.categoryId == categoryId)
        .length;
  }

  String? _normalizedImageUrl(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          color: AppColors.redColor,
          onRefresh: _loadCategories,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
            children: [
              AdminResponsiveSplit(
                breakpoint: 1080,
                spacing: 20,
                primaryFlex: 5,
                secondaryFlex: 4,
                primary: _buildComposerCard(),
                secondary: _buildGuideCard(),
              ),
              const SizedBox(height: 22),
              _buildLibraryHeader(),
              const SizedBox(height: 14),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.redColor),
                  ),
                )
              else if (_categories.isEmpty)
                const AdminEmptyPanel(
                  icon: Icons.category_outlined,
                  title: 'No categories yet',
                  description:
                      'Upload your first category image and publish it from the form above.',
                )
              else
                _buildCategoryGrid(isWide: constraints.maxWidth >= 900),
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
            title: _editingCategory == null
                ? 'Create Category'
                : 'Edit Category',
            subtitle:
                'Built for desktop admin work. Add a category name, then either upload artwork or paste a trusted image URL for the storefront card.',
          ),
          const SizedBox(height: 22),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(text: 'Category Name'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Category name is required';
                    }
                    return null;
                  },
                  decoration: _inputDecoration(
                    hintText: 'Example: New Arrivals',
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sortOrderController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          hintText: 'Sort order',
                        ).copyWith(labelText: 'Sort Order'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isVisible,
                        onChanged: (value) =>
                            setState(() => _isVisible = value),
                        title: const Text('Visible'),
                        subtitle: Text(
                          _isVisible
                              ? 'Shown in storefront'
                              : 'Hidden from storefront',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: _inputDecoration(
                    hintText: 'Optional image URL',
                  ).copyWith(labelText: 'Image URL'),
                ),
                const SizedBox(height: 18),
                const _SectionLabel(text: 'Category Image'),
                const SizedBox(height: 10),
                _ImageUploadCard(
                  bytes: _selectedImageBytes,
                  fileName: _selectedImage?.name ?? _editingCategory?.imageUrl,
                  isPickingImage: _isPickingImage,
                  onPickImage: _pickImage,
                  onRemoveImage: () {
                    setState(() {
                      _selectedImage = null;
                      _selectedImageBytes = null;
                    });
                  },
                ),
                const SizedBox(height: 22),
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
                              onPressed: _saveCategory,
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
                                _editingCategory == null
                                    ? 'Publish Category'
                                    : 'Save Changes',
                              ),
                            ),
                    ),
                    if (_editingCategory != null) ...[
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
                if (_saveStatusMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.redColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _saveStatusMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blackColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    return const AdminSurfaceCard(
      backgroundColor: AppColors.blackColor,
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTag(
            label: 'Web Workflow',
            backgroundColor: Color(0x1AFFFFFF),
            foregroundColor: Colors.white,
          ),
          SizedBox(height: 18),
          Text(
            'Use wide visuals, strong names, and one clean image per category.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          SizedBox(height: 18),
          _GuidePoint(
            title: 'Use horizontal-friendly artwork',
            description:
                'Choose images that still read well in desktop cards and grids.',
          ),
          SizedBox(height: 14),
          _GuidePoint(
            title: 'Keep names short',
            description:
                'Strong names like Bags, Shoes, and Electronics scan faster.',
          ),
          SizedBox(height: 14),
          _GuidePoint(
            title: 'Use upload or URL',
            description:
                'You can now upload artwork directly or paste a trusted CDN image URL when your team already hosts category art.',
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryHeader() {
    return AdminSectionIntro(
      title: 'Category Library',
      subtitle:
          'Search categories, control storefront visibility, and tune the sort order from one compact admin view.',
      trailing: SizedBox(
        width: 260,
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search categories',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid({required bool isWide}) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _filteredCategories.map((category) {
        return SizedBox(
          width: isWide ? 260 : double.infinity,
          child: _CategoryCard(
            category: category,
            linkedProductsCount: _linkedProductsCount(category.id),
            onEdit: () => _startEditing(category),
            onDelete: () => _deleteCategory(category),
            onToggleVisibility: () => _toggleCategoryVisibility(category),
            onMoveUp: () => _moveCategorySort(category, -1),
            onMoveDown: () => _moveCategorySort(category, 1),
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
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
}

class _ImageUploadCard extends StatelessWidget {
  const _ImageUploadCard({
    required this.bytes,
    required this.fileName,
    required this.isPickingImage,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final Uint8List? bytes;
  final String? fileName;
  final bool isPickingImage;
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
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 42,
                            color: AppColors.redColor,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Upload category image',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.blackColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Best for web admin: clean artwork, square or landscape.',
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.linkedProductsCount,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleVisibility,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final CategoryModel category;
  final int linkedProductsCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: AspectRatio(
              aspectRatio: 1.7,
              child: Image.network(
                category.imageUrl ?? '',
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.imageUrl ?? 'No image available',
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
                    AdminTag(
                      label:
                          '$linkedProductsCount product${linkedProductsCount == 1 ? '' : 's'}',
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.blackColor,
                      isCompact: true,
                    ),
                    AdminTag(
                      label: category.isVisible ? 'Visible' : 'Hidden',
                      backgroundColor: category.isVisible
                          ? const Color(0xFFE8F7ED)
                          : const Color(0xFFFFE4E6),
                      foregroundColor: category.isVisible
                          ? const Color(0xFF1E8E5A)
                          : Colors.red,
                      isCompact: true,
                    ),
                    AdminTag(
                      label: 'Sort ${category.sortOrder}',
                      isCompact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: [
                      IconButton(
                        onPressed: onMoveUp,
                        tooltip: 'Move up',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        icon: const Icon(Icons.arrow_upward_rounded, size: 19),
                      ),
                      IconButton(
                        onPressed: onMoveDown,
                        tooltip: 'Move down',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        icon: const Icon(Icons.arrow_downward_rounded, size: 19),
                      ),
                      IconButton(
                        onPressed: onToggleVisibility,
                        tooltip: category.isVisible ? 'Hide' : 'Show',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        icon: Icon(
                          category.isVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 19,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.blackColor,
      ),
    );
  }
}

class _GuidePoint extends StatelessWidget {
  const _GuidePoint({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: AppColors.redColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.check, size: 16, color: AppColors.redColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFFD5D5D5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
