// ignore_for_file: invalid_use_of_protected_member

part of 'admin_promotion_screen.dart';

extension _AdminPromotionScreenActions on _AdminPromotionScreenState {
  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

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
    final minOrder =
        double.tryParse(_couponMinOrderController.text.trim()) ?? 0;
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
      String? imageUrl =
          _normalizedImageUrl(_bannerImageUrlController.text) ??
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
    final ordered = [..._banners]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
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
    _couponMaxDiscountController.text =
        coupon.maxDiscountAmount?.toString() ?? '';
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
}
