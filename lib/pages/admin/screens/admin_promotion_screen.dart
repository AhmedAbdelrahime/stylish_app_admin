import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/core/realtime/supabase_realtime_reloader.dart';
import 'package:hungry/pages/admin/data/admin_banner_model.dart';
import 'package:hungry/pages/admin/data/admin_coupon_model.dart';
import 'package:hungry/pages/admin/data/admin_offer_model.dart';
import 'package:hungry/pages/admin/data/admin_promotion_service.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'admin_promotion_screen_sections.dart';
part 'admin_promotion_cards.dart';
part 'admin_promotion_upload_widgets.dart';
part 'admin_promotion_screen_actions.dart';

class AdminPromotionScreen extends StatefulWidget {
  const AdminPromotionScreen({super.key});

  @override
  State<AdminPromotionScreen> createState() => _AdminPromotionScreenState();
}

class _AdminPromotionScreenState extends State<AdminPromotionScreen> {
  final AdminPromotionService _promotionService = AdminPromotionService();
  final SupabaseClient _supabase = Supabase.instance.client;

  final _couponFormKey = GlobalKey<FormState>();
  final _bannerFormKey = GlobalKey<FormState>();
  final _offerFormKey = GlobalKey<FormState>();

  final TextEditingController _couponCodeController = TextEditingController();
  final TextEditingController _couponDescriptionController =
      TextEditingController();
  final TextEditingController _couponDiscountValueController =
      TextEditingController();
  final TextEditingController _couponMinOrderController = TextEditingController(
    text: '0',
  );
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
  final TextEditingController _offerImageUrlController =
      TextEditingController();
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
  SupabaseRealtimeReloader? _realtimeReloader;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _setupRealtime();
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _realtimeReloader?.dispose();
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
      channelName: 'admin-promotions-${DateTime.now().microsecondsSinceEpoch}',
      tables: const ['coupons', 'banners', 'offers'],
      onReload: () {
        if (_isSavingCoupon ||
            _isSavingBanner ||
            _isSavingOffer ||
            _isDeleting ||
            _isPickingBannerImage ||
            _isPickingOfferImage) {
          return Future<void>.value();
        }
        return _loadData(showLoading: false);
      },
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
}
