import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/admin/data/admin_product_import_service.dart';
import 'package:hungry/pages/admin/logic/product/cubit/admin_product_cubit.dart';
import 'package:hungry/pages/admin/logic/product/cubit/admin_product_state.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/home/models/category_model.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:image_picker/image_picker.dart';
part 'admin_product_composer_section.dart';
part 'admin_product_library_section.dart';
part 'admin_product_form_fields.dart';
part 'admin_product_upload_widgets.dart';
part 'admin_product_card.dart';
part 'admin_product_import_preview.dart';
part 'admin_product_screen_actions.dart';

class AdminProductScreen extends StatelessWidget {
  const AdminProductScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminProductCubit(),
      child: const _AdminProductView(),
    );
  }
}

class _AdminProductView extends StatefulWidget {
  const _AdminProductView();
  @override
  State<_AdminProductView> createState() => _AdminProductViewState();
}

class _AdminProductViewState extends State<_AdminProductView> {
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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPickingImage = false;
  bool _isImporting = false;
  bool _isExporting = false;
  bool _isFeatured = false;
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
  Timer? _searchDebounce;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminProductCubit, AdminProductState>(
      builder: (context, productState) {
        return LayoutBuilder(
          builder: (context, _) {
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
                    primary: _buildComposerCard(productState),
                    secondary: _buildLibraryCard(productState),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
