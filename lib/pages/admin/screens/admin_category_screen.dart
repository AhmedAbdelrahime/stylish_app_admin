import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/core/realtime/supabase_realtime_reloader.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/home/data/category_service.dart';
import 'package:hungry/pages/home/data/product_service.dart';
import 'package:hungry/pages/home/models/category_model.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'admin_category_screen_sections.dart';
part 'admin_category_upload_widgets.dart';
part 'admin_category_card.dart';
part 'admin_category_support_widgets.dart';

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
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseRealtimeReloader? _realtimeReloader;
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
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _realtimeReloader?.dispose();
    _nameController.dispose();
    _imageUrlController.dispose();
    _sortOrderController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
    });
  }

  void _setupRealtime() {
    _realtimeReloader = SupabaseRealtimeReloader(
      supabase: _supabase,
      channelName: 'admin-categories-${DateTime.now().microsecondsSinceEpoch}',
      tables: const ['categories', 'products'],
      onReload: () {
        if (_isSaving || _isDeleting || _isPickingImage) {
          return Future<void>.value();
        }
        return _loadCategories(showLoading: false);
      },
    );
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

  Future<void> _loadCategories({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final results =
          await Future.wait([
            _categoryService.getCategories(),
            _productService.getAllProducts(),
          ]).timeout(
            _categoryRequestTimeout,
            onTimeout: () =>
                throw 'Loading categories took too long. Please try again.',
          );

      final categories = results[0] as List<CategoryModel>;
      final products = results[1] as List<ProductModel>;
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _products = products;
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

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    final isEditing = _editingCategory != null;
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

      final currentImageUrl = _selectedImage != null
          ? await _uploadSelectedCategoryImage()
          : _normalizedImageUrl(_imageUrlController.text) ??
                _editingCategory?.imageUrl;

      if (!mounted) return;

      if (currentImageUrl == null || currentImageUrl.trim().isEmpty) {
        AppSnackBar.show(
          context: context,
          text:
              'Please upload a category image or paste an image URL before saving.',
          icon: Icons.image_not_supported_outlined,
          backgroundColor: Colors.red,
        );
        return;
      }

      if (!isEditing) {
        setState(() {
          _saveStatusMessage = 'Creating category record...';
        });
        await _categoryService
            .createCategory(
              name: _nameController.text.trim(),
              imageUrl: currentImageUrl,
              isVisible: _isVisible,
              sortOrder: sortOrder,
            )
            .timeout(
              _categoryRequestTimeout,
              onTimeout: () =>
                  throw 'Saving the category took too long. Please try again.',
            );
      } else {
        setState(() {
          _saveStatusMessage = 'Updating category record...';
        });
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
              onTimeout: () =>
                  throw 'Updating the category took too long. Please try again.',
            );
      }

      setState(() {
        _saveStatusMessage = 'Refreshing category list...';
      });
      await _loadCategories(showLoading: false).timeout(
        _categoryRequestTimeout,
        onTimeout: () =>
            throw 'Refreshing categories took too long after save.',
      );
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
      return _categoryService
          .uploadCategoryImageBytes(
            bytes: selectedImageBytes,
            fileName: selectedImage.name,
            mimeType: selectedImage.mimeType,
          )
          .timeout(
            _categoryRequestTimeout,
            onTimeout: () =>
                throw 'Image upload took too long. Please check your connection and storage setup.',
          );
    }

    return _categoryService
        .uploadCategoryImage(selectedImage)
        .timeout(
          _categoryRequestTimeout,
          onTimeout: () =>
              throw 'Image upload took too long. Please check your connection and storage setup.',
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
      await _loadCategories(showLoading: false);
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: category.isVisible
            ? '${category.name} is now hidden.'
            : '${category.name} is now visible.',
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
      await _loadCategories(showLoading: false);
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: delta < 0
            ? '${category.name} moved up.'
            : '${category.name} moved down.',
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
      await _loadCategories(showLoading: false);

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
}
