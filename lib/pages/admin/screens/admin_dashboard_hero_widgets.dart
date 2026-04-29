part of 'admin_dashboard_screen.dart';

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.dashboard, required this.onRefresh});

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
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
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
  const _HeroMetric({required this.label, required this.value});

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
              padding: EdgeInsets.only(
                bottom: entry.key == priorities.length - 1 ? 0 : 14,
              ),
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
