part of 'admin_dashboard_screen.dart';

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
        Expanded(
          child: _SummaryPill(label: leftLabel, value: leftValue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryPill(label: rightLabel, value: rightValue),
        ),
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
            helper:
                '${dashboard.paidOrdersCount} of ${dashboard.orders.length} orders paid',
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
