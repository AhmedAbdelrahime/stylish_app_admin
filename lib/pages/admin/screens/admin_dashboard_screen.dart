import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/core/realtime/supabase_realtime_reloader.dart';
import 'package:hungry/pages/admin/data/admin_banner_model.dart';
import 'package:hungry/pages/admin/data/admin_coupon_model.dart';
import 'package:hungry/pages/admin/data/admin_offer_model.dart';
import 'package:hungry/pages/admin/data/admin_order_model.dart';
import 'package:hungry/pages/admin/data/admin_order_service.dart';
import 'package:hungry/pages/admin/data/admin_promotion_service.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/home/data/category_service.dart';
import 'package:hungry/pages/home/data/product_service.dart';
import 'package:hungry/pages/home/models/category_model.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:hungry/pages/settings/data/profile_service.dart';
import 'package:hungry/pages/settings/data/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
part 'admin_dashboard_models.dart';
part 'admin_dashboard_hero_widgets.dart';
part 'admin_dashboard_panels.dart';
part 'admin_dashboard_shared_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final ProfileService _profileService = ProfileService();
  final AdminOrderService _orderService = AdminOrderService();
  final AdminPromotionService _promotionService = AdminPromotionService();
  SupabaseRealtimeReloader? _realtimeReloader;

  late Future<_DashboardSnapshot> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadSnapshot();
    _setupRealtime();
  }

  @override
  void dispose() {
    _realtimeReloader?.dispose();
    super.dispose();
  }

  void _setupRealtime() {
    _realtimeReloader = SupabaseRealtimeReloader(
      supabase: _supabase,
      channelName: 'admin-dashboard-${DateTime.now().microsecondsSinceEpoch}',
      tables: const [
        'products',
        'categories',
        'profiles',
        'orders',
        'order_items',
        'coupons',
        'banners',
        'offers',
      ],
      onReload: _refresh,
    );
  }

  Future<_DashboardSnapshot> _loadSnapshot() async {
    final results = await Future.wait<dynamic>([
      _safeLoad<List<ProductModel>>(
        task: _productService.getDashboardProducts,
        fallback: const [],
        label: 'products',
      ),
      _safeLoad<List<CategoryModel>>(
        task: _categoryService.getDashboardCategories,
        fallback: const [],
        label: 'categories',
      ),
      _safeLoad<List<UserModel>>(
        task: _profileService.getDashboardProfiles,
        fallback: const [],
        label: 'profiles',
      ),
      _safeLoad<List<AdminOrderModel>>(
        task: _orderService.getDashboardOrders,
        fallback: const [],
        label: 'orders',
      ),
      _safeLoad<List<AdminCouponModel>>(
        task: _promotionService.getDashboardCoupons,
        fallback: const [],
        label: 'coupons',
      ),
      _safeLoad<List<AdminBannerModel>>(
        task: _promotionService.getDashboardBanners,
        fallback: const [],
        label: 'banners',
      ),
      _safeLoad<List<AdminOfferModel>>(
        task: _promotionService.getDashboardOffers,
        fallback: const [],
        label: 'offers',
      ),
    ]);

    return _DashboardSnapshot(
      products: results[0] as List<ProductModel>,
      categories: results[1] as List<CategoryModel>,
      users: results[2] as List<UserModel>,
      orders: results[3] as List<AdminOrderModel>,
      coupons: results[4] as List<AdminCouponModel>,
      banners: results[5] as List<AdminBannerModel>,
      offers: results[6] as List<AdminOfferModel>,
    );
  }

  Future<T> _safeLoad<T>({
    required Future<T> Function() task,
    required T fallback,
    required String label,
  }) async {
    try {
      return await task();
    } catch (error, stackTrace) {
      debugPrint('[AdminDashboard] load_$label:error $error');
      debugPrintStack(
        label: '[AdminDashboard] load_$label:stack',
        stackTrace: stackTrace,
      );
      return fallback;
    }
  }

  Future<void> _refresh() async {
    final future = _loadSnapshot();
    if (!mounted) return;
    setState(() {
      _dashboardFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardSnapshot>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.redColor),
          );
        }

        if (snapshot.hasError && !snapshot.hasData) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AdminEmptyPanel(
                icon: Icons.analytics_outlined,
                title: 'Could not load dashboard',
                description:
                    'The overview could not read your live admin data. Try refreshing after checking Supabase access.',
              ),
            ),
          );
        }

        final dashboard = snapshot.data ?? _DashboardSnapshot.empty();

        return RefreshIndicator(
          color: AppColors.redColor,
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stats = _buildStats(dashboard);

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
                children: [
                  AdminResponsiveSplit(
                    breakpoint: 1080,
                    spacing: 20,
                    primaryFlex: 7,
                    secondaryFlex: 4,
                    primary: _HeroCard(
                      dashboard: dashboard,
                      onRefresh: _refresh,
                    ),
                    secondary: _TodayPrioritiesCard(dashboard: dashboard),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: stats
                        .map(
                          (stat) => SizedBox(
                            width: constraints.maxWidth >= 1200
                                ? (constraints.maxWidth - 48) / 4
                                : constraints.maxWidth >= 760
                                ? (constraints.maxWidth - 16) / 2
                                : double.infinity,
                            child: _DashboardStatCard(stat: stat),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  AdminResponsiveSplit(
                    breakpoint: 1080,
                    spacing: 20,
                    primaryFlex: 6,
                    secondaryFlex: 5,
                    primary: _BusinessPulsePanel(dashboard: dashboard),
                    secondary: _AlertsPanel(dashboard: dashboard),
                  ),
                  const SizedBox(height: 20),
                  AdminResponsiveSplit(
                    breakpoint: 1080,
                    spacing: 20,
                    primaryFlex: 6,
                    secondaryFlex: 5,
                    primary: _RecentOrdersPanel(dashboard: dashboard),
                    secondary: _InsightsPanel(dashboard: dashboard),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<_DashboardStat> _buildStats(_DashboardSnapshot dashboard) {
    return [
      _DashboardStat(
        title: 'Revenue',
        value: dashboard.formattedRevenue,
        change: dashboard.revenueDeltaLabel,
        icon: Icons.payments_outlined,
        tone: dashboard.totalRevenue >= dashboard.previousMonthRevenue
            ? _DashboardStatTone.positive
            : _DashboardStatTone.warning,
      ),
      _DashboardStat(
        title: 'Orders',
        value: dashboard.orders.length.toString(),
        change: dashboard.ordersDeltaLabel,
        icon: Icons.receipt_long_outlined,
        tone: dashboard.pendingOrdersCount > 0
            ? _DashboardStatTone.warning
            : _DashboardStatTone.positive,
      ),
      _DashboardStat(
        title: 'Catalog',
        value: '${dashboard.products.length} products',
        change:
            '${dashboard.lowStockCount} low stock, ${dashboard.outOfStockCount} out',
        icon: Icons.inventory_2_outlined,
        tone: dashboard.outOfStockCount > 0
            ? _DashboardStatTone.critical
            : dashboard.lowStockCount > 0
            ? _DashboardStatTone.warning
            : _DashboardStatTone.positive,
      ),
      _DashboardStat(
        title: 'Users',
        value: dashboard.users.length.toString(),
        change: '${dashboard.adminCount} admins managing',
        icon: Icons.people_alt_outlined,
        tone: _DashboardStatTone.neutral,
      ),
    ];
  }
}
