part of 'admin_dashboard_screen.dart';

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

  int get hiddenProductsCount => products
      .where((product) => product.status.toLowerCase() == 'hidden')
      .length;

  int get draftProductsCount => products
      .where((product) => product.status.toLowerCase() == 'draft')
      .length;

  int get featuredProductsCount =>
      products.where((product) => product.featured).length;

  int get activeCouponsCount =>
      coupons.where((coupon) => coupon.isActive && !coupon.isExpired).length;

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

  int get currentMonthOrders => orders
      .where(
        (order) =>
            order.createdAt != null &&
            order.createdAt!.year == _now.year &&
            order.createdAt!.month == _now.month,
      )
      .length;

  int get previousMonthOrders {
    final previousMonth = DateTime(_now.year, _now.month - 1);
    return orders
        .where(
          (order) =>
              order.createdAt != null &&
              order.createdAt!.year == previousMonth.year &&
              order.createdAt!.month == previousMonth.month,
        )
        .length;
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
      items.add(
        '$hiddenCategoriesCount hidden categories need storefront review',
      );
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
