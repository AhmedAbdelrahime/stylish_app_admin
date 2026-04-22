import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';
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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final ProfileService _profileService = ProfileService();
  final AdminOrderService _orderService = AdminOrderService();
  final AdminPromotionService _promotionService = AdminPromotionService();

  late Future<_DashboardSnapshot> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadSnapshot();
  }

  Future<_DashboardSnapshot> _loadSnapshot() async {
    final results = await Future.wait<dynamic>([
      _safeLoad<List<ProductModel>>(
        task: _productService.getAllProducts,
        fallback: const [],
        label: 'products',
      ),
      _safeLoad<List<CategoryModel>>(
        task: _categoryService.getCategories,
        fallback: const [],
        label: 'categories',
      ),
      _safeLoad<List<UserModel>>(
        task: _profileService.getAllProfiles,
        fallback: const [],
        label: 'profiles',
      ),
      _safeLoad<List<AdminOrderModel>>(
        task: _orderService.getOrders,
        fallback: const [],
        label: 'orders',
      ),
      _safeLoad<List<AdminCouponModel>>(
        task: _promotionService.getCoupons,
        fallback: const [],
        label: 'coupons',
      ),
      _safeLoad<List<AdminBannerModel>>(
        task: _promotionService.getBanners,
        fallback: const [],
        label: 'banners',
      ),
      _safeLoad<List<AdminOfferModel>>(
        task: _promotionService.getOffers,
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
        change: '${dashboard.lowStockCount} low stock, ${dashboard.outOfStockCount} out',
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

class _DashboardSnapshot {
  const _DashboardSnapshot({
    required this.products,
    required this.categories,
    required this.users,
    required this.orders,
    required this.coupons,
    required this.banners,
    required this.offers,
  });

  factory _DashboardSnapshot.empty() => const _DashboardSnapshot(
    products: [],
    categories: [],
    users: [],
    orders: [],
    coupons: [],
    banners: [],
    offers: [],
  );

  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final List<UserModel> users;
  final List<AdminOrderModel> orders;
  final List<AdminCouponModel> coupons;
  final List<AdminBannerModel> banners;
  final List<AdminOfferModel> offers;

  double get totalRevenue =>
      orders.fold(0, (sum, order) => sum + order.totalAmount);

  double get paidRevenue => orders
      .where((order) => order.paymentStatus.toLowerCase() == 'paid')
      .fold(0, (sum, order) => sum + order.totalAmount);

  int get paidOrdersCount => orders
      .where((order) => order.paymentStatus.toLowerCase() == 'paid')
      .length;

  int get pendingOrdersCount =>
      orders.where((order) => order.status.toLowerCase() == 'pending').length;

  int get processingOrdersCount => orders
      .where((order) => order.status.toLowerCase() == 'processing')
      .length;

  int get deliveryQueueCount => orders
      .where((order) => order.deliveryStatus.toLowerCase() != 'delivered')
      .length;

  int get adminCount =>
      users.where((user) => user.role?.toLowerCase() == 'admin').length;

  int get visibleCategoriesCount =>
      categories.where((category) => category.isVisible).length;

  int get hiddenCategoriesCount =>
      categories.where((category) => !category.isVisible).length;

  int get lowStockCount =>
      products.where((product) => product.isLowStock).length;

  int get outOfStockCount =>
      products.where((product) => product.stockQuantity <= 0).length;

  int get hiddenProductsCount =>
      products.where((product) => product.status.toLowerCase() == 'hidden').length;

  int get draftProductsCount =>
      products.where((product) => product.status.toLowerCase() == 'draft').length;

  int get featuredProductsCount =>
      products.where((product) => product.featured).length;

  int get activeCouponsCount => coupons
      .where((coupon) => coupon.isActive && !coupon.isExpired)
      .length;

  int get activeBannersCount =>
      banners.where((banner) => banner.isActive).length;

  int get offerCount => offers.length;

  List<AdminOrderModel> get recentOrders => orders.take(6).toList();

  DateTime get _now => DateTime.now();

  String get primaryCurrency {
    for (final order in orders) {
      final currency = order.currency.trim();
      if (currency.isNotEmpty) {
        return currency.toUpperCase();
      }
    }
    return 'INR';
  }

  double get currentMonthRevenue => orders
      .where(
        (order) =>
            order.createdAt != null &&
            order.createdAt!.year == _now.year &&
            order.createdAt!.month == _now.month,
      )
      .fold(0, (sum, order) => sum + order.totalAmount);

  double get previousMonthRevenue {
    final previousMonth = DateTime(_now.year, _now.month - 1);
    return orders
        .where(
          (order) =>
              order.createdAt != null &&
              order.createdAt!.year == previousMonth.year &&
              order.createdAt!.month == previousMonth.month,
        )
        .fold(0, (sum, order) => sum + order.totalAmount);
  }

  int get currentMonthOrders => orders.where(
    (order) =>
        order.createdAt != null &&
        order.createdAt!.year == _now.year &&
        order.createdAt!.month == _now.month,
  ).length;

  int get previousMonthOrders {
    final previousMonth = DateTime(_now.year, _now.month - 1);
    return orders.where(
      (order) =>
          order.createdAt != null &&
          order.createdAt!.year == previousMonth.year &&
          order.createdAt!.month == previousMonth.month,
    ).length;
  }

  double get paymentHealthRatio =>
      orders.isEmpty ? 0 : paidOrdersCount / orders.length;

  double get catalogReadinessRatio {
    if (products.isEmpty) return 0;
    final readyProducts = products.where(
      (product) =>
          product.status.toLowerCase() == 'active' &&
          product.stockQuantity > 0 &&
          product.primaryImage.isNotEmpty,
    );
    return readyProducts.length / products.length;
  }

  double get visibilityRatio =>
      categories.isEmpty ? 0 : visibleCategoriesCount / categories.length;

  List<_DashboardAlert> get alerts {
    final items = <_DashboardAlert>[];

    if (outOfStockCount > 0) {
      items.add(
        _DashboardAlert(
          title: '$outOfStockCount products are unavailable',
          description:
              'Restock them or hide them from storefront to prevent a broken shopping experience.',
          severity: _AlertSeverity.critical,
        ),
      );
    }
    if (pendingOrdersCount > 0) {
      items.add(
        _DashboardAlert(
          title: '$pendingOrdersCount orders need action',
          description:
              'Review payment and fulfillment states so the queue does not pile up.',
          severity: _AlertSeverity.warning,
        ),
      );
    }
    if (hiddenCategoriesCount > 0) {
      items.add(
        _DashboardAlert(
          title: '$hiddenCategoriesCount categories are hidden',
          description:
              'Check if hidden collections should remain off the storefront.',
          severity: _AlertSeverity.info,
        ),
      );
    }
    if (coupons.isNotEmpty && activeCouponsCount == 0) {
      items.add(
        _DashboardAlert(
          title: 'Coupons exist but none are active',
          description:
              'Enable a valid campaign if you want promotions to appear during checkout.',
          severity: _AlertSeverity.info,
        ),
      );
    }
    if (banners.isNotEmpty && activeBannersCount == 0) {
      items.add(
        _DashboardAlert(
          title: 'Banners are configured but disabled',
          description:
              'Activate at least one banner to keep the storefront fresh and promotional.',
          severity: _AlertSeverity.info,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const _DashboardAlert(
          title: 'No urgent store issues detected',
          description:
              'Orders, inventory, and promotions look stable right now.',
          severity: _AlertSeverity.success,
        ),
      );
    }

    return items.take(4).toList();
  }

  List<_LabeledValue> get topCategoryBreakdown {
    final productCounts = <String, int>{};
    for (final product in products) {
      final key = product.categoryId;
      if (key == null || key.isEmpty) continue;
      productCounts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }

    final lookup = {
      for (final category in categories) category.id: category.name,
    };

    final maxCount = productCounts.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxCount == 0) return const [];

    final entries = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(4).map((entry) {
      final label = lookup[entry.key] ?? 'Unknown category';
      return _LabeledValue(
        label: label,
        value: '${entry.value} items',
        widthFactor: entry.value / maxCount,
      );
    }).toList();
  }

  List<_LabeledValue> get orderStatusBreakdown {
    final counts = <String, int>{};
    for (final order in orders) {
      final label = _titleCase(order.status);
      counts.update(label, (value) => value + 1, ifAbsent: () => 1);
    }

    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxCount == 0) return const [];

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(4).map((entry) {
      return _LabeledValue(
        label: entry.key,
        value: '${entry.value} orders',
        widthFactor: entry.value / maxCount,
      );
    }).toList();
  }

  List<String> get priorities {
    final items = <String>[];

    if (pendingOrdersCount > 0) {
      items.add('$pendingOrdersCount pending orders need review');
    }
    if (lowStockCount > 0) {
      items.add('$lowStockCount products are running low on stock');
    }
    if (outOfStockCount > 0) {
      items.add('$outOfStockCount products are out of stock');
    }
    if (hiddenCategoriesCount > 0) {
      items.add('$hiddenCategoriesCount hidden categories need storefront review');
    }
    if (activeCouponsCount == 0 && coupons.isNotEmpty) {
      items.add('No coupons are currently active');
    }
    if (activeBannersCount == 0 && banners.isNotEmpty) {
      items.add('No active banners are showing on storefront');
    }

    if (items.isEmpty) {
      items.add('Store operations look healthy right now');
      items.add('Use this dashboard to monitor growth and merchandising');
    }

    return items.take(4).toList();
  }

  String get formattedRevenue => _formatMoney(totalRevenue, primaryCurrency);

  String get formattedPaidRevenue => _formatMoney(paidRevenue, primaryCurrency);

  String get averageOrderValue => orders.isEmpty
      ? _formatMoney(0, primaryCurrency)
      : _formatMoney(totalRevenue / orders.length, primaryCurrency);

  String get completionRate {
    if (orders.isEmpty) return '0%';
    final completed = orders
        .where((order) => order.status.toLowerCase() == 'completed')
        .length;
    final percent = (completed / orders.length) * 100;
    return '${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}%';
  }

  String get revenueDeltaLabel {
    final delta = currentMonthRevenue - previousMonthRevenue;
    if (previousMonthRevenue <= 0) {
      return '${_monthLabel(_now)} ${_formatMoney(currentMonthRevenue, primaryCurrency)}';
    }
    final percent = ((delta / previousMonthRevenue) * 100).abs();
    final prefix = delta >= 0 ? '+' : '-';
    return '$prefix${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}% vs last month';
  }

  String get ordersDeltaLabel {
    final delta = currentMonthOrders - previousMonthOrders;
    if (previousMonthOrders <= 0) {
      return '${currentMonthOrders.toString()} this month';
    }
    final percent = ((delta / previousMonthOrders) * 100).abs();
    final prefix = delta >= 0 ? '+' : '-';
    return '$prefix${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}% vs last month';
  }

  static String _formatMoney(double amount, String currency) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first;
    final decimal = parts.last;
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final indexFromEnd = whole.length - i;
      buffer.write(whole[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${_currencySymbol(currency)}${buffer.toString()}.$decimal';
  }

  static String _titleCase(String value) {
    if (value.trim().isEmpty) return 'Unknown';
    return value
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static String _monthLabel(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[value.month - 1];
  }

  static String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '${currency.toUpperCase()} ';
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.dashboard,
    required this.onRefresh,
  });

  final _DashboardSnapshot dashboard;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161B24), Color(0xFF2A3242)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: AdminSurfaceCard(
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Live admin signals from your real catalog, users, orders, and promotions. Pull down to refresh or use the refresh action here.',
                        style: TextStyle(
                          color: Color(0xFFE2E2E2),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh overview',
                  onPressed: onRefresh,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AdminTag(
                  label: '${dashboard.orders.length} total orders',
                  backgroundColor: const Color(0x1AFFFFFF),
                  foregroundColor: Colors.white,
                ),
                AdminTag(
                  label: '${dashboard.products.length} products',
                  backgroundColor: const Color(0x1AFFFFFF),
                  foregroundColor: Colors.white,
                ),
                AdminTag(
                  label: '${dashboard.activeCouponsCount} active coupons',
                  backgroundColor: const Color(0x1AFFFFFF),
                  foregroundColor: Colors.white,
                ),
                AdminTag(
                  label: '${dashboard.activeBannersCount} live banners',
                  backgroundColor: const Color(0x1AFFFFFF),
                  foregroundColor: Colors.white,
                ),
                AdminTag(
                  label:
                      '${_DashboardSnapshot._monthLabel(DateTime.now())} live snapshot',
                  backgroundColor: const Color(0x1AFFFFFF),
                  foregroundColor: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _HeroMetric(
                  label: 'Paid revenue',
                  value: dashboard.formattedPaidRevenue,
                ),
                _HeroMetric(
                  label: 'Average order',
                  value: dashboard.averageOrderValue,
                ),
                _HeroMetric(
                  label: 'Completion',
                  value: dashboard.completionRate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD8D8D8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPrioritiesCard extends StatelessWidget {
  const _TodayPrioritiesCard({required this.dashboard});

  final _DashboardSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    final priorities = dashboard.priorities;

    return AdminSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Priorities',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Live operational checks based on current dashboard data.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 18),
          ...priorities.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key == priorities.length - 1 ? 0 : 14),
              child: _PriorityTile(
                title: entry.value,
                subtitle: _prioritySubtitle(entry.value),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _prioritySubtitle(String title) {
    if (title.contains('pending orders')) {
      return 'Update payment, fulfillment, and delivery states before the queue grows.';
    }
    if (title.contains('running low')) {
      return 'Restock or reduce visibility for products that may soon sell out.';
    }
    if (title.contains('out of stock')) {
      return 'Hide unavailable products or refill inventory to protect storefront quality.';
    }
    if (title.contains('hidden categories')) {
      return 'Check whether hidden collections should return to the storefront.';
    }
    if (title.contains('coupons')) {
      return 'Review coupon dates and active campaigns so checkout promotions stay current.';
    }
    if (title.contains('banners')) {
      return 'Enable at least one active banner so storefront marketing stays fresh.';
    }
    return 'The overview is healthy. Use this page as your first check-in before deeper admin tasks.';
  }
}

class _RecentOrdersPanel extends StatelessWidget {
  const _RecentOrdersPanel({required this.dashboard});

  final _DashboardSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    final orders = dashboard.recentOrders;

    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'Recent Orders',
            subtitle: 'Latest live orders from the current store activity.',
          ),
          const SizedBox(height: 20),
          if (orders.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              description:
                  'Once users start checking out, recent orders will appear here with live totals and statuses.',
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: _TableHeader('Order')),
                  Expanded(flex: 3, child: _TableHeader('User')),
                  Expanded(flex: 2, child: _TableHeader('Total')),
                  Expanded(flex: 2, child: _TableHeader('Status')),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OrderTableRow(order: order),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightsPanel extends StatelessWidget {
  const _InsightsPanel({required this.dashboard});

  final _DashboardSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    final categoryBreakdown = dashboard.topCategoryBreakdown;
    final orderBreakdown = dashboard.orderStatusBreakdown;

    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'Live Insights',
            subtitle:
                'A real snapshot of catalog health, order flow, and promotions.',
          ),
          const SizedBox(height: 18),
          _InsightSummaryRow(
            leftLabel: 'Low stock',
            leftValue: dashboard.lowStockCount.toString(),
            rightLabel: 'Out of stock',
            rightValue: dashboard.outOfStockCount.toString(),
          ),
          const SizedBox(height: 12),
          _InsightSummaryRow(
            leftLabel: 'Featured',
            leftValue: dashboard.featuredProductsCount.toString(),
            rightLabel: 'Draft / Hidden',
            rightValue:
                '${dashboard.draftProductsCount} / ${dashboard.hiddenProductsCount}',
          ),
          const SizedBox(height: 12),
          _InsightSummaryRow(
            leftLabel: 'Coupons / Banners',
            leftValue:
                '${dashboard.activeCouponsCount} / ${dashboard.activeBannersCount}',
            rightLabel: 'Offers',
            rightValue: dashboard.offerCount.toString(),
          ),
          if (categoryBreakdown.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'Top Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.blackColor,
              ),
            ),
            const SizedBox(height: 12),
            ...categoryBreakdown.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _InsightBar(
                  label: entry.label,
                  value: entry.value,
                  widthFactor: entry.widthFactor,
                ),
              ),
            ),
          ],
          if (orderBreakdown.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Order Pipeline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.blackColor,
              ),
            ),
            const SizedBox(height: 12),
            ...orderBreakdown.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _InsightBar(
                  label: entry.label,
                  value: entry.value,
                  widthFactor: entry.widthFactor,
                ),
              ),
            ),
          ],
          if (categoryBreakdown.isEmpty && orderBreakdown.isEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Add more live data to products, categories, and orders to unlock fuller analytics here.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.hintColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightSummaryRow extends StatelessWidget {
  const _InsightSummaryRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryPill(label: leftLabel, value: leftValue)),
        const SizedBox(width: 10),
        Expanded(child: _SummaryPill(label: rightLabel, value: rightValue)),
      ],
    );
  }
}

class _BusinessPulsePanel extends StatelessWidget {
  const _BusinessPulsePanel({required this.dashboard});

  final _DashboardSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'Business Pulse',
            subtitle:
                'Operational health built from live orders, catalog readiness, and storefront visibility.',
          ),
          const SizedBox(height: 20),
          _PulseMetricRow(
            label: 'Payment health',
            value:
                '${(dashboard.paymentHealthRatio * 100).toStringAsFixed(dashboard.paymentHealthRatio == 0 ? 0 : 1)}%',
            helper: '${dashboard.paidOrdersCount} of ${dashboard.orders.length} orders paid',
            progress: dashboard.paymentHealthRatio,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _PulseMetricRow(
            label: 'Catalog readiness',
            value:
                '${(dashboard.catalogReadinessRatio * 100).toStringAsFixed(dashboard.catalogReadinessRatio == 0 ? 0 : 1)}%',
            helper:
                '${dashboard.products.where((product) => product.status.toLowerCase() == 'active' && product.stockQuantity > 0 && product.primaryImage.isNotEmpty).length} active products ready to sell',
            progress: dashboard.catalogReadinessRatio,
            color: AppColors.redColor,
          ),
          const SizedBox(height: 16),
          _PulseMetricRow(
            label: 'Category visibility',
            value:
                '${(dashboard.visibilityRatio * 100).toStringAsFixed(dashboard.visibilityRatio == 0 ? 0 : 1)}%',
            helper:
                '${dashboard.visibleCategoriesCount} visible of ${dashboard.categories.length} total categories',
            progress: dashboard.visibilityRatio,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel({required this.dashboard});

  final _DashboardSnapshot dashboard;

  @override
  Widget build(BuildContext context) {
    final alerts = dashboard.alerts;

    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'Alerts',
            subtitle:
                'Professional admin teams stay ahead by resolving issues before they hit the storefront.',
          ),
          const SizedBox(height: 18),
          ...alerts.asMap().entries.map((entry) {
            final alert = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == alerts.length - 1 ? 0 : 14,
              ),
              child: _AlertTile(alert: alert),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStat {
  const _DashboardStat({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String value;
  final String change;
  final IconData icon;
  final _DashboardStatTone tone;
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({required this.stat});

  final _DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    final tone = _resolveTone();

    return AdminSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: tone.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(stat.icon, color: tone.color),
          ),
          const SizedBox(height: 18),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            stat.change,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tone.color,
            ),
          ),
        ],
      ),
    );
  }

  _DashboardStatToneStyle _resolveTone() {
    switch (stat.tone) {
      case _DashboardStatTone.positive:
        return const _DashboardStatToneStyle(Colors.green);
      case _DashboardStatTone.warning:
        return const _DashboardStatToneStyle(Colors.orange);
      case _DashboardStatTone.critical:
        return const _DashboardStatToneStyle(AppColors.redColor);
      case _DashboardStatTone.neutral:
        return const _DashboardStatToneStyle(AppColors.redColor);
    }
  }
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          height: 10,
          width: 10,
          decoration: const BoxDecoration(
            color: AppColors.redColor,
            shape: BoxShape.circle,
          ),
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
                  color: AppColors.blackColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.hintColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderTableRow extends StatelessWidget {
  const _OrderTableRow({required this.order});

  final AdminOrderModel order;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              order.orderCode,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.blackColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              order.displayCustomerName,
              style: const TextStyle(color: AppColors.hintColor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _DashboardSnapshot._formatMoney(order.totalAmount, order.currency),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.blackColor,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _DashboardSnapshot._titleCase(order.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.grey;
      case 'pending':
      default:
        return AppColors.redColor;
    }
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.hintColor,
        letterSpacing: .3,
      ),
    );
  }
}

class _InsightBar extends StatelessWidget {
  const _InsightBar({
    required this.label,
    required this.value,
    required this.widthFactor,
  });

  final String label;
  final String value;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackColor,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * widthFactor.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: AppColors.redColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LabeledValue {
  const _LabeledValue({
    required this.label,
    required this.value,
    required this.widthFactor,
  });

  final String label;
  final String value;
  final double widthFactor;
}

enum _DashboardStatTone { positive, warning, critical, neutral }

class _DashboardStatToneStyle {
  const _DashboardStatToneStyle(this.color);

  final Color color;
}

enum _AlertSeverity { critical, warning, info, success }

class _DashboardAlert {
  const _DashboardAlert({
    required this.title,
    required this.description,
    required this.severity,
  });

  final String title;
  final String description;
  final _AlertSeverity severity;
}

class _PulseMetricRow extends StatelessWidget {
  const _PulseMetricRow({
    required this.label,
    required this.value,
    required this.helper,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blackColor,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.hintColor,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress.clamp(0.0, 1.0),
            color: color,
            backgroundColor: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final _DashboardAlert alert;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(alert.severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: style.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alert.description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: AppColors.hintColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AdminTag(
            label: style.label,
            backgroundColor: style.accent.withValues(alpha: 0.14),
            foregroundColor: style.accent,
            isCompact: true,
          ),
        ],
      ),
    );
  }

  _AlertStyle _styleFor(_AlertSeverity severity) {
    switch (severity) {
      case _AlertSeverity.critical:
        return const _AlertStyle(
          label: 'Critical',
          accent: AppColors.redColor,
          border: Color(0xFFFFD5D1),
          background: Color(0xFFFFF3F2),
          icon: Icons.error_outline,
        );
      case _AlertSeverity.warning:
        return const _AlertStyle(
          label: 'Warning',
          accent: Colors.orange,
          border: Color(0xFFFFE2B3),
          background: Color(0xFFFFF7E8),
          icon: Icons.warning_amber_outlined,
        );
      case _AlertSeverity.info:
        return const _AlertStyle(
          label: 'Info',
          accent: Colors.blue,
          border: Color(0xFFD6E7FF),
          background: Color(0xFFF3F8FF),
          icon: Icons.info_outline,
        );
      case _AlertSeverity.success:
        return const _AlertStyle(
          label: 'Stable',
          accent: Colors.green,
          border: Color(0xFFD4F0D7),
          background: Color(0xFFF0FBF1),
          icon: Icons.verified_outlined,
        );
    }
  }
}

class _AlertStyle {
  const _AlertStyle({
    required this.label,
    required this.accent,
    required this.border,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color accent;
  final Color border;
  final Color background;
  final IconData icon;
}
