import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/admin/data/admin_banner_model.dart';
import 'package:hungry/pages/admin/data/admin_coupon_model.dart';
import 'package:hungry/pages/admin/data/admin_offer_model.dart';
import 'package:hungry/pages/admin/data/admin_promotion_service.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';

class AdminPromotionScreen extends StatefulWidget {
  const AdminPromotionScreen({super.key});

  @override
  State<AdminPromotionScreen> createState() => _AdminPromotionScreenState();
}

class _AdminPromotionScreenState extends State<AdminPromotionScreen> {
  final AdminPromotionService _promotionService = AdminPromotionService();

  final _couponFormKey = GlobalKey<FormState>();
  final _bannerFormKey = GlobalKey<FormState>();
  final _offerFormKey = GlobalKey<FormState>();

  final TextEditingController _couponCodeController = TextEditingController();
  final TextEditingController _couponDescriptionController =
      TextEditingController();
  final TextEditingController _couponDiscountValueController =
      TextEditingController();
  final TextEditingController _couponMinOrderController =
      TextEditingController(text: '0');
  final TextEditingController _couponMaxDiscountController =
      TextEditingController();
  final TextEditingController _couponUsageLimitController =
      TextEditingController();

  final TextEditingController _bannerTitleController = TextEditingController();
  final TextEditingController _bannerSubtitleController =
      TextEditingController();
  final TextEditingController _bannerImageUrlController =
      TextEditingController();
  final TextEditingController _bannerTargetValueController =
      TextEditingController();
  final TextEditingController _bannerSortOrderController =
      TextEditingController(text: '0');
  final TextEditingController _offerTitleController = TextEditingController();
  final TextEditingController _offerImageUrlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<AdminCouponModel> _coupons = const [];
  List<AdminBannerModel> _banners = const [];
  List<AdminOfferModel> _offers = const [];
  bool _isLoading = true;
  bool _isSavingCoupon = false;
  bool _isSavingBanner = false;
  bool _isSavingOffer = false;
  bool _isPickingBannerImage = false;
  bool _isPickingOfferImage = false;
  bool _isDeleting = false;
  String _searchQuery = '';
  String _couponType = 'percent';
  bool _couponActive = true;
  String _bannerTargetType = 'url';
  bool _bannerActive = true;
  AdminCouponModel? _editingCoupon;
  AdminBannerModel? _editingBanner;
  AdminOfferModel? _editingOffer;
  XFile? _selectedBannerImage;
  Uint8List? _selectedBannerImageBytes;
  XFile? _selectedOfferImage;
  Uint8List? _selectedOfferImageBytes;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    _couponDescriptionController.dispose();
    _couponDiscountValueController.dispose();
    _couponMinOrderController.dispose();
    _couponMaxDiscountController.dispose();
    _couponUsageLimitController.dispose();
    _bannerTitleController.dispose();
    _bannerSubtitleController.dispose();
    _bannerImageUrlController.dispose();
    _bannerTargetValueController.dispose();
    _bannerSortOrderController.dispose();
    _offerTitleController.dispose();
    _offerImageUrlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _promotionService.getCoupons(),
        _promotionService.getBanners(),
        _promotionService.getOffers(),
      ]);

      if (!mounted) return;
      setState(() {
        _coupons = results[0] as List<AdminCouponModel>;
        _banners = results[1] as List<AdminBannerModel>;
        _offers = results[2] as List<AdminOfferModel>;
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

  Future<void> _saveCoupon() async {
    if (!_couponFormKey.currentState!.validate()) return;

    final discountValue =
        double.tryParse(_couponDiscountValueController.text.trim()) ?? 0;
    final minOrder = double.tryParse(_couponMinOrderController.text.trim()) ?? 0;
    final maxDiscount = _parseOptionalDouble(_couponMaxDiscountController.text);
    final usageLimit = _parseOptionalInt(_couponUsageLimitController.text);

    setState(() => _isSavingCoupon = true);
    try {
      if (_editingCoupon == null) {
        await _promotionService.createCoupon(
          code: _couponCodeController.text,
          description: _couponDescriptionController.text,
          discountType: _couponType,
          discountValue: discountValue,
          minOrderAmount: minOrder,
          maxDiscountAmount: maxDiscount,
          usageLimit: usageLimit,
          isActive: _couponActive,
        );
      } else {
        await _promotionService.updateCoupon(
          id: _editingCoupon!.id,
          code: _couponCodeController.text,
          description: _couponDescriptionController.text,
          discountType: _couponType,
          discountValue: discountValue,
          minOrderAmount: minOrder,
          maxDiscountAmount: maxDiscount,
          usageLimit: usageLimit,
          isActive: _couponActive,
        );
      }
      await _loadData();
      _resetCouponForm();
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: _editingCoupon == null
            ? 'Coupon created successfully.'
            : 'Coupon updated successfully.',
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
        setState(() => _isSavingCoupon = false);
      }
    }
  }

  Future<void> _saveBanner() async {
    if (!_bannerFormKey.currentState!.validate()) return;

    final sortOrder = int.tryParse(_bannerSortOrderController.text.trim()) ?? 0;
    setState(() => _isSavingBanner = true);
    try {
      String? imageUrl = _normalizedImageUrl(_bannerImageUrlController.text) ??
          _editingBanner?.imageUrl;

      if (_selectedBannerImage != null && _selectedBannerImageBytes != null) {
        imageUrl = await _promotionService.uploadPromotionImageBytes(
          bytes: _selectedBannerImageBytes!,
          fileName: _selectedBannerImage!.name,
          mimeType: _selectedBannerImage!.mimeType,
          folder: 'banners',
        );
      }

      if (imageUrl == null || imageUrl.isEmpty) {
        throw 'Please upload a banner image or provide an image URL.';
      }

      if (_editingBanner == null) {
        await _promotionService.createBanner(
          title: _bannerTitleController.text,
          subtitle: _bannerSubtitleController.text,
          imageUrl: imageUrl,
          targetType: _bannerTargetType,
          targetValue: _bannerTargetValueController.text,
          isActive: _bannerActive,
          sortOrder: sortOrder,
        );
      } else {
        await _promotionService.updateBanner(
          id: _editingBanner!.id,
          title: _bannerTitleController.text,
          subtitle: _bannerSubtitleController.text,
          imageUrl: imageUrl,
          targetType: _bannerTargetType,
          targetValue: _bannerTargetValueController.text,
          isActive: _bannerActive,
          sortOrder: sortOrder,
        );
      }
      await _loadData();
      _resetBannerForm();
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: _editingBanner == null
            ? 'Banner created successfully.'
            : 'Banner updated successfully.',
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
        setState(() => _isSavingBanner = false);
      }
    }
  }

  Future<void> _saveOffer() async {
    if (!_offerFormKey.currentState!.validate()) return;

    setState(() => _isSavingOffer = true);
    try {
      String? imageUrl =
          _normalizedImageUrl(_offerImageUrlController.text) ??
          _editingOffer?.imageUrl;

      if (_selectedOfferImage != null && _selectedOfferImageBytes != null) {
        imageUrl = await _promotionService.uploadPromotionImageBytes(
          bytes: _selectedOfferImageBytes!,
          fileName: _selectedOfferImage!.name,
          mimeType: _selectedOfferImage!.mimeType,
          folder: 'offers',
        );
      }

      if (imageUrl == null || imageUrl.isEmpty) {
        throw 'Please upload an offer image or provide an image URL.';
      }

      if (_editingOffer == null) {
        await _promotionService.createOffer(
          imageUrl: imageUrl,
          title: _offerTitleController.text,
        );
      } else {
        await _promotionService.updateOffer(
          id: _editingOffer!.id,
          imageUrl: imageUrl,
          title: _offerTitleController.text,
        );
      }

      await _loadData();
      _resetOfferForm();
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: _editingOffer == null
            ? 'Offer created successfully.'
            : 'Offer updated successfully.',
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
        setState(() => _isSavingOffer = false);
      }
    }
  }

  Future<void> _deleteCoupon(AdminCouponModel coupon) async {
    final shouldDelete = await _confirmDelete(
      'Delete coupon',
      'Delete coupon code ${coupon.code} permanently?',
    );
    if (shouldDelete != true) return;
    setState(() => _isDeleting = true);
    try {
      await _promotionService.deleteCoupon(coupon.id);
      await _loadData();
      if (_editingCoupon?.id == coupon.id) {
        _resetCouponForm();
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _deleteBanner(AdminBannerModel banner) async {
    final shouldDelete = await _confirmDelete(
      'Delete banner',
      'Delete banner "${banner.title}" permanently?',
    );
    if (shouldDelete != true) return;
    setState(() => _isDeleting = true);
    try {
      await _promotionService.deleteBanner(banner.id);
      await _loadData();
      if (_editingBanner?.id == banner.id) {
        _resetBannerForm();
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _deleteOffer(AdminOfferModel offer) async {
    final shouldDelete = await _confirmDelete(
      'Delete offer',
      'Delete offer "${offer.title ?? offer.id}" permanently?',
    );
    if (shouldDelete != true) return;
    setState(() => _isDeleting = true);
    try {
      await _promotionService.deleteOffer(offer.id);
      await _loadData();
      if (_editingOffer?.id == offer.id) {
        _resetOfferForm();
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _toggleCoupon(AdminCouponModel coupon) async {
    await _promotionService.updateCouponActiveState(
      id: coupon.id,
      isActive: !coupon.isActive,
    );
    await _loadData();
  }

  Future<void> _moveBanner(AdminBannerModel banner, int delta) async {
    final ordered = [..._banners]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final currentIndex = ordered.indexWhere((item) => item.id == banner.id);
    if (currentIndex == -1) return;
    final targetIndex = currentIndex + delta;
    if (targetIndex < 0 || targetIndex >= ordered.length) return;
    final reordered = [...ordered];
    final moved = reordered.removeAt(currentIndex);
    reordered.insert(targetIndex, moved);
    await _promotionService.reorderBanners(reordered);
    await _loadData();
  }

  Future<bool?> _confirmDelete(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
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
  }

  void _startEditingCoupon(AdminCouponModel coupon) {
    _couponCodeController.text = coupon.code;
    _couponDescriptionController.text = coupon.description ?? '';
    _couponDiscountValueController.text = coupon.discountValue.toString();
    _couponMinOrderController.text = coupon.minOrderAmount.toString();
    _couponMaxDiscountController.text = coupon.maxDiscountAmount?.toString() ?? '';
    _couponUsageLimitController.text = coupon.usageLimit?.toString() ?? '';
    setState(() {
      _editingCoupon = coupon;
      _couponType = coupon.discountType;
      _couponActive = coupon.isActive;
    });
  }

  void _startEditingBanner(AdminBannerModel banner) {
    _bannerTitleController.text = banner.title;
    _bannerSubtitleController.text = banner.subtitle ?? '';
    _bannerImageUrlController.text = banner.imageUrl;
    _bannerTargetValueController.text = banner.targetValue ?? '';
    _bannerSortOrderController.text = banner.sortOrder.toString();
    setState(() {
      _editingBanner = banner;
      _bannerTargetType = banner.targetType;
      _bannerActive = banner.isActive;
    });
  }

  void _startEditingOffer(AdminOfferModel offer) {
    _offerTitleController.text = offer.title ?? '';
    _offerImageUrlController.text = offer.imageUrl;
    setState(() {
      _editingOffer = offer;
      _selectedOfferImage = null;
      _selectedOfferImageBytes = null;
    });
  }

  void _resetCouponForm() {
    _couponCodeController.clear();
    _couponDescriptionController.clear();
    _couponDiscountValueController.clear();
    _couponMinOrderController.text = '0';
    _couponMaxDiscountController.clear();
    _couponUsageLimitController.clear();
    setState(() {
      _editingCoupon = null;
      _couponType = 'percent';
      _couponActive = true;
    });
  }

  void _resetBannerForm() {
    _bannerTitleController.clear();
    _bannerSubtitleController.clear();
    _bannerImageUrlController.clear();
    _bannerTargetValueController.clear();
    _bannerSortOrderController.text = '0';
    setState(() {
      _editingBanner = null;
      _bannerTargetType = 'url';
      _bannerActive = true;
      _selectedBannerImage = null;
      _selectedBannerImageBytes = null;
    });
  }

  void _resetOfferForm() {
    _offerTitleController.clear();
    _offerImageUrlController.clear();
    setState(() {
      _editingOffer = null;
      _selectedOfferImage = null;
      _selectedOfferImageBytes = null;
    });
  }

  List<AdminCouponModel> get _filteredCoupons {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _coupons;
    return _coupons.where((coupon) {
      return [
        coupon.code,
        coupon.description ?? '',
        coupon.discountType,
      ].join(' ').toLowerCase().contains(query);
    }).toList();
  }

  List<AdminBannerModel> get _filteredBanners {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _banners;
    return _banners.where((banner) {
      return [
        banner.title,
        banner.subtitle ?? '',
        banner.targetType,
        banner.targetValue ?? '',
      ].join(' ').toLowerCase().contains(query);
    }).toList();
  }

  List<AdminOfferModel> get _filteredOffers {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _offers;
    return _offers.where((offer) {
      return [
        offer.title ?? '',
        offer.imageUrl,
      ].join(' ').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _pickBannerImage() async {
    try {
      setState(() => _isPickingBannerImage = true);
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedBannerImage = picked;
        _selectedBannerImageBytes = bytes;
      });
    } finally {
      if (mounted) setState(() => _isPickingBannerImage = false);
    }
  }

  Future<void> _pickOfferImage() async {
    try {
      setState(() => _isPickingOfferImage = true);
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedOfferImage = picked;
        _selectedOfferImageBytes = bytes;
      });
    } finally {
      if (mounted) setState(() => _isPickingOfferImage = false);
    }
  }

  double? _parseOptionalDouble(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  int? _parseOptionalInt(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _normalizedImageUrl(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.redColor,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
        children: [
          AdminResponsiveSplit(
            breakpoint: 1180,
            spacing: 20,
            primaryFlex: 5,
            secondaryFlex: 4,
            primary: _buildCouponComposer(),
            secondary: _buildBannerComposer(),
          ),
          const SizedBox(height: 20),
          _buildOfferComposer(),
          const SizedBox(height: 20),
          _buildSearchHeader(),
          const SizedBox(height: 18),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: CircularProgressIndicator(color: AppColors.redColor),
              ),
            )
          else ...[
            _buildCouponSection(),
            const SizedBox(height: 20),
            _buildBannerSection(),
            const SizedBox(height: 20),
            _buildOfferSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return AdminSectionIntro(
      title: 'Promotions Library',
      subtitle:
          'Manage coupon campaigns and storefront banners from one clean admin view.',
      trailing: SizedBox(
        width: 260,
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: _inputDecoration(
            'Search promotions',
          ).copyWith(prefixIcon: const Icon(Icons.search_rounded)),
        ),
      ),
    );
  }

  Widget _buildCouponComposer() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _couponFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionIntro(
              title: _editingCoupon == null ? 'Create Coupon' : 'Edit Coupon',
              subtitle:
                  'Set discount rules, activation state, and order thresholds the same way most admin apps handle promo codes.',
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _couponCodeController,
              validator: _requiredValidator,
              decoration: _inputDecoration('Coupon code', hintText: 'SAVE20'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _couponDescriptionController,
              decoration: _inputDecoration('Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _couponType,
                    decoration: _inputDecoration('Discount type'),
                    items: const [
                      DropdownMenuItem(value: 'percent', child: Text('Percent')),
                      DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _couponType = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _couponDiscountValueController,
                    validator: _requiredValidator,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration('Discount value'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couponMinOrderController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration('Minimum order'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _couponMaxDiscountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration('Max discount'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _couponUsageLimitController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Usage limit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _couponActive,
              onChanged: (value) => setState(() => _couponActive = value),
              title: const Text('Coupon is active'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (_isSavingCoupon || _isDeleting) ? null : _saveCoupon,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.redColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSavingCoupon
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _editingCoupon == null
                                ? 'Create Coupon'
                                : 'Save Coupon',
                          ),
                  ),
                ),
                if (_editingCoupon != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetCouponForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  Widget _buildBannerComposer() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _bannerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionIntro(
              title: _editingBanner == null ? 'Create Banner' : 'Edit Banner',
              subtitle:
                  'Control hero banners, link targets, active state, and storefront order from one professional admin form.',
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _bannerTitleController,
              validator: _requiredValidator,
              decoration: _inputDecoration('Banner title'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bannerSubtitleController,
              decoration: _inputDecoration('Subtitle'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bannerImageUrlController,
              decoration: _inputDecoration(
                'Image URL',
                hintText: 'Optional fallback URL',
              ),
            ),
            const SizedBox(height: 12),
            _PromotionImageUploadCard(
              title: 'Upload banner image',
              description:
                  'Upload the hero artwork here, or keep a direct image URL above when your media is already hosted.',
              bytes: _selectedBannerImageBytes,
              fileName: _selectedBannerImage?.name ?? _editingBanner?.imageUrl,
              isPickingImage: _isPickingBannerImage,
              onPickImage: _pickBannerImage,
              onRemoveImage: () {
                setState(() {
                  _selectedBannerImage = null;
                  _selectedBannerImageBytes = null;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _bannerTargetType,
                    decoration: _inputDecoration('Target type'),
                    items: const [
                      DropdownMenuItem(value: 'url', child: Text('URL')),
                      DropdownMenuItem(value: 'product', child: Text('Product')),
                      DropdownMenuItem(value: 'category', child: Text('Category')),
                      DropdownMenuItem(value: 'offer', child: Text('Offer')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _bannerTargetType = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bannerTargetValueController,
                    decoration: _inputDecoration('Target value'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bannerSortOrderController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Sort order'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _bannerActive,
              onChanged: (value) => setState(() => _bannerActive = value),
              title: const Text('Banner is active'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (_isSavingBanner || _isDeleting) ? null : _saveBanner,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blackColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSavingBanner
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _editingBanner == null
                                ? 'Create Banner'
                                : 'Save Banner',
                          ),
                  ),
                ),
                if (_editingBanner != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetBannerForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  Widget _buildOfferComposer() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _offerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSectionIntro(
              title: _editingOffer == null ? 'Create Offer' : 'Edit Offer',
              subtitle:
                  'Manage simple storefront promo cards for your home slider, with image upload first and URL as an optional fallback.',
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _offerTitleController,
              decoration: _inputDecoration('Offer title'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _offerImageUrlController,
              decoration: _inputDecoration(
                'Image URL',
                hintText: 'Optional fallback URL',
              ),
            ),
            const SizedBox(height: 12),
            _PromotionImageUploadCard(
              title: 'Upload offer image',
              description:
                  'Use upload for the main offer artwork, or keep a URL above if your media is already hosted elsewhere.',
              bytes: _selectedOfferImageBytes,
              fileName: _selectedOfferImage?.name ?? _editingOffer?.imageUrl,
              isPickingImage: _isPickingOfferImage,
              onPickImage: _pickOfferImage,
              onRemoveImage: () {
                setState(() {
                  _selectedOfferImage = null;
                  _selectedOfferImageBytes = null;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (_isSavingOffer || _isDeleting) ? null : _saveOffer,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.redColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSavingOffer
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _editingOffer == null
                                ? 'Create Offer'
                                : 'Save Offer',
                          ),
                  ),
                ),
                if (_editingOffer != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetOfferForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }

  Widget _buildCouponSection() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'Coupon Library',
            subtitle:
                'Monitor active codes, order thresholds, and usage so campaigns stay clean and support can scan them quickly.',
          ),
          const SizedBox(height: 16),
          if (_filteredCoupons.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.sell_outlined,
              title: 'No coupons yet',
              description:
                  'Create your first coupon to start discount campaigns and checkout promotions.',
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _filteredCoupons.map((coupon) {
                return SizedBox(
                  width: 320,
                  child: _CouponCard(
                    coupon: coupon,
                    onEdit: () => _startEditingCoupon(coupon),
                    onDelete: () => _deleteCoupon(coupon),
                    onToggle: () => _toggleCoupon(coupon),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'Banner Library',
            subtitle:
                'Keep storefront banners ordered, active, and linked to the right destinations.',
          ),
          const SizedBox(height: 16),
          if (_filteredBanners.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.photo_size_select_actual_outlined,
              title: 'No banners yet',
              description:
                  'Create your first hero banner to control the top of the storefront.',
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _filteredBanners.map((banner) {
                return SizedBox(
                  width: 360,
                  child: _BannerCard(
                    banner: banner,
                    onEdit: () => _startEditingBanner(banner),
                    onDelete: () => _deleteBanner(banner),
                    onMoveUp: () => _moveBanner(banner, -1),
                    onMoveDown: () => _moveBanner(banner, 1),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildOfferSection() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'Offer Library',
            subtitle:
                'Keep simple storefront offer cards updated for the home slider and other lightweight promo surfaces.',
          ),
          const SizedBox(height: 16),
          if (_filteredOffers.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.local_offer_outlined,
              title: 'No offers yet',
              description:
                  'Create your first offer card to feed the storefront slider with simple visual promotions.',
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _filteredOffers.map((offer) {
                return SizedBox(
                  width: 320,
                  child: _OfferCard(
                    offer: offer,
                    onEdit: () => _startEditingOffer(offer),
                    onDelete: () => _deleteOffer(offer),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final AdminCouponModel coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDanger = coupon.isExpired || !coupon.isActive;

    return AdminSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  coupon.code,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
              ),
              AdminTag(
                label: coupon.isActive ? 'Active' : 'Inactive',
                backgroundColor: isDanger
                    ? const Color(0xFFFFE4E6)
                    : const Color(0xFFE8F7ED),
                foregroundColor: isDanger
                    ? Colors.red
                    : const Color(0xFF1E8E5A),
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            coupon.description ?? 'No description',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminTag(
                label: '${coupon.discountValue} ${coupon.discountType}',
                isCompact: true,
              ),
              AdminTag(
                label: 'Used ${coupon.usedCount}',
                isCompact: true,
              ),
              AdminTag(
                label: 'Min ${coupon.minOrderAmount}',
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: onToggle,
                tooltip: coupon.isActive ? 'Deactivate' : 'Activate',
                icon: Icon(
                  coupon.isActive
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete',
                color: Colors.red,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final AdminBannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: AspectRatio(
              aspectRatio: 1.9,
              child: Image.network(
                banner.imageUrl,
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  banner.subtitle ?? 'No subtitle',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminTag(
                      label: banner.isActive ? 'Active' : 'Inactive',
                      isCompact: true,
                    ),
                    AdminTag(
                      label: banner.targetType,
                      isCompact: true,
                    ),
                    AdminTag(
                      label: 'Sort ${banner.sortOrder}',
                      isCompact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  banner.targetValue ?? 'No target value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: onMoveUp,
                      tooltip: 'Move up',
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                    IconButton(
                      onPressed: onMoveDown,
                      tooltip: 'Move down',
                      icon: const Icon(Icons.arrow_downward_rounded),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      color: Colors.red,
                      icon: const Icon(Icons.delete_outline),
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminOfferModel offer;
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
            child: AspectRatio(
              aspectRatio: 1.8,
              child: Image.network(
                offer.imageUrl,
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title ?? 'Untitled offer',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.imageUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      color: Colors.red,
                      icon: const Icon(Icons.delete_outline),
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

class _PromotionImageUploadCard extends StatelessWidget {
  const _PromotionImageUploadCard({
    required this.title,
    required this.description,
    required this.bytes,
    required this.fileName,
    required this.isPickingImage,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final String title;
  final String description;
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
            height: 180,
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
                            Icons.add_photo_alternate_outlined,
                            size: 42,
                            color: AppColors.redColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.blackColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.hintColor,
                              ),
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
                  hasImage ? (fileName ?? 'Selected image') : 'No image selected',
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
                    : const Icon(Icons.upload_file_outlined),
                label: Text(hasImage ? 'Change' : 'Upload'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
