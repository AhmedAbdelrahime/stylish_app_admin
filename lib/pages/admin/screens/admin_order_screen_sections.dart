// ignore_for_file: invalid_use_of_protected_member

part of 'admin_order_screen.dart';

extension _AdminOrderViewSections on _AdminOrderViewState {
  Widget _buildSummarySection(
    List<AdminOrderModel> orders,
    List<AdminOrderModel> filteredOrders,
  ) {
    final currency = filteredOrders.isEmpty
        ? (orders.isEmpty ? 'USD' : orders.first.currency)
        : filteredOrders.first.currency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionIntro(
          title: 'Orders Command Center',
          subtitle:
              'Review new orders, filter by date, track payment and delivery progress, and export the current queue in one professional admin view.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _OrderMetricCard(
              icon: Icons.receipt_long_outlined,
              label: 'Visible orders',
              value: '${filteredOrders.length}',
              accentColor: AppColors.redColor,
            ),
            _OrderMetricCard(
              icon: Icons.hourglass_top_rounded,
              label: 'Pending review',
              value: '${_pendingOrdersCount(filteredOrders)}',
              accentColor: const Color(0xFFB06A00),
            ),
            _OrderMetricCard(
              icon: Icons.local_shipping_outlined,
              label: 'Open delivery queue',
              value: '${_deliveryQueueCount(filteredOrders)}',
              accentColor: const Color(0xFF2558C5),
            ),
            _OrderMetricCard(
              icon: Icons.payments_outlined,
              label: 'Visible revenue',
              value: _formatMoney(_filteredRevenue(filteredOrders), currency),
              accentColor: const Color(0xFF1E8E5A),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpsGuideCard() {
    return const AdminSurfaceCard(
      backgroundColor: AppColors.blackColor,
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTag(
            label: 'Operations',
            backgroundColor: Color(0x1AFFFFFF),
            foregroundColor: Colors.white,
          ),
          SizedBox(height: 18),
          Text(
            'Handle each order the way most modern admin apps do: scan fast, filter by time window, export the live queue, and dive into details only when needed.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          SizedBox(height: 18),
          _GuidePoint(
            title: 'Use date filters daily',
            description:
                'Narrow the queue to today, this week, or a support follow-up window before triaging order issues.',
          ),
          SizedBox(height: 14),
          _GuidePoint(
            title: 'Update payment and delivery separately',
            description:
                'This keeps finance and fulfillment aligned when one status moves before the others.',
          ),
          SizedBox(height: 14),
          _GuidePoint(
            title: 'Export the exact queue you are viewing',
            description:
                'Filtered export makes it easier to share a pack list or reconciliation sheet with the team.',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(
    List<AdminOrderModel> orders,
    List<AdminOrderModel> filteredOrders,
  ) {
    final currency = filteredOrders.isEmpty
        ? (orders.isEmpty ? 'USD' : orders.first.currency)
        : filteredOrders.first.currency;
    final statusCounts = _statusCounts(filteredOrders);

    return AdminResponsiveSplit(
      breakpoint: 1120,
      spacing: 20,
      primaryFlex: 5,
      secondaryFlex: 4,
      primary: AdminSurfaceCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionIntro(
              title: 'Order Analytics',
              subtitle:
                  'Live analytics reflect the current filter set, so managers can review the exact queue they are working on.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AnalyticsChip(
                  label: 'Paid revenue',
                  value: _formatMoney(_paidRevenue(filteredOrders), currency),
                ),
                _AnalyticsChip(
                  label: 'Avg order value',
                  value: _formatMoney(
                    _averageOrderValue(filteredOrders),
                    currency,
                  ),
                ),
                _AnalyticsChip(
                  label: 'Completion rate',
                  value:
                      '${(_completionRate(filteredOrders) * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 18),
            ..._AdminOrderViewState._orderStatuses.map(
              (status) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AnalyticsBar(
                  label: status,
                  value: statusCounts[status] ?? 0,
                  total: filteredOrders.length,
                  color: _statusColor(status),
                ),
              ),
            ),
          ],
        ),
      ),
      secondary: AdminSurfaceCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionIntro(
              title: 'Date Window',
              subtitle:
                  'Filter by order creation date to review a shift, campaign, or fulfillment batch.',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _DateFilterButton(
                    label: 'From',
                    value: _formatDate(_fromDate),
                    onTap: _pickFromDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateFilterButton(
                    label: 'To',
                    value: _formatDate(_toDate),
                    onTap: _pickToDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: (_fromDate == null && _toDate == null)
                      ? null
                      : _clearDateRange,
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  label: const Text('Clear date range'),
                ),
                FilledButton.icon(
                  onPressed: filteredOrders.isEmpty || _isExporting
                      ? null
                      : () => _exportFilteredOrders(filteredOrders),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blackColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isExporting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export current view'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersPanel(
    List<AdminOrderModel> orders,
    List<AdminOrderModel> filteredOrders,
  ) {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionIntro(
            title: 'Order Library',
            subtitle:
                'Search by order ID, customer, status, address, or amount, then update fulfillment inline.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 940;
              final children = [
                _FilterDropdown(
                  label: 'Order status',
                  value: _statusFilter,
                  items: const [
                    ('all', 'All statuses'),
                    ('pending', 'Pending'),
                    ('processing', 'Processing'),
                    ('completed', 'Completed'),
                    ('cancelled', 'Cancelled'),
                  ],
                  onChanged: (value) => setState(() => _statusFilter = value!),
                ),
                _FilterDropdown(
                  label: 'Payment',
                  value: _paymentFilter,
                  items: const [
                    ('all', 'All payments'),
                    ('pending', 'Pending'),
                    ('paid', 'Paid'),
                    ('refunded', 'Refunded'),
                    ('failed', 'Failed'),
                  ],
                  onChanged: (value) => setState(() => _paymentFilter = value!),
                ),
                _FilterDropdown(
                  label: 'Delivery',
                  value: _deliveryFilter,
                  items: const [
                    ('all', 'All deliveries'),
                    ('pending', 'Pending'),
                    ('packed', 'Packed'),
                    ('shipped', 'Shipped'),
                    ('delivered', 'Delivered'),
                  ],
                  onChanged: (value) =>
                      setState(() => _deliveryFilter = value!),
                ),
              ];

              if (!isWide) {
                return Column(
                  children: children
                      .map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: child,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: [
                  Expanded(child: children[0]),
                  const SizedBox(width: 12),
                  Expanded(child: children[1]),
                  const SizedBox(width: 12),
                  Expanded(child: children[2]),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: _inputDecoration('Search orders').copyWith(
              hintText: 'Search by order, customer, address, or amount',
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          if (orders.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${filteredOrders.length} order${filteredOrders.length == 1 ? '' : 's'} shown. ${_processingOrdersCount(filteredOrders)} currently in processing.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.hintColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
