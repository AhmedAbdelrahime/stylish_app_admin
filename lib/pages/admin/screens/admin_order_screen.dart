import 'dart:io';

import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/admin/data/admin_order_model.dart';
import 'package:hungry/pages/admin/data/admin_order_service.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  static const _orderStatuses = [
    'pending',
    'processing',
    'completed',
    'cancelled',
  ];

  static const _paymentStatuses = [
    'pending',
    'paid',
    'refunded',
    'failed',
  ];

  static const _deliveryStatuses = [
    'pending',
    'packed',
    'shipped',
    'delivered',
  ];

  final TextEditingController _searchController = TextEditingController();
  final AdminOrderService _orderService = AdminOrderService();

  List<AdminOrderModel> _orders = const [];
  bool _isLoading = true;
  bool _isExporting = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _paymentFilter = 'all';
  String _deliveryFilter = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _updatingOrderId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderService.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  Future<void> _updateOrderStatus({
    required AdminOrderModel order,
    String? status,
    String? paymentStatus,
    String? deliveryStatus,
  }) async {
    setState(() => _updatingOrderId = order.id);
    try {
      await _orderService.updateOrderStatuses(
        orderId: order.id,
        status: status,
        paymentStatus: paymentStatus,
        deliveryStatus: deliveryStatus,
      );
      await _loadOrders();
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: '${order.orderCode} updated successfully.',
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
        setState(() => _updatingOrderId = null);
      }
    }
  }

  List<AdminOrderModel> get _filteredOrders {
    final query = _searchQuery.trim().toLowerCase();
    return _orders.where((order) {
      if (_statusFilter != 'all' && order.status != _statusFilter) {
        return false;
      }
      if (_paymentFilter != 'all' && order.paymentStatus != _paymentFilter) {
        return false;
      }
      if (_deliveryFilter != 'all' &&
          order.deliveryStatus != _deliveryFilter) {
        return false;
      }
      if (!_isInSelectedDateRange(order.createdAt)) {
        return false;
      }

      if (query.isEmpty) return true;

      final haystack = [
        order.id,
        order.orderCode,
        order.displayCustomerName,
        order.user?.email ?? '',
        order.status,
        order.paymentStatus,
        order.deliveryStatus,
        order.shippingAddress ?? '',
        order.totalAmount.toStringAsFixed(2),
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  double get _filteredRevenue =>
      _filteredOrders.fold<double>(0, (sum, order) => sum + order.totalAmount);

  double get _paidRevenue => _filteredOrders
      .where((order) => order.paymentStatus == 'paid')
      .fold<double>(0, (sum, order) => sum + order.totalAmount);

  int get _pendingOrdersCount =>
      _filteredOrders.where((order) => order.status == 'pending').length;

  int get _processingOrdersCount =>
      _filteredOrders.where((order) => order.status == 'processing').length;

  int get _deliveryQueueCount => _filteredOrders
      .where((order) => order.deliveryStatus != 'delivered')
      .length;

  double get _averageOrderValue {
    if (_filteredOrders.isEmpty) return 0;
    return _filteredRevenue / _filteredOrders.length;
  }

  double get _completionRate {
    if (_filteredOrders.isEmpty) return 0;
    final completedCount = _filteredOrders
        .where((order) => order.status == 'completed')
        .length;
    return completedCount / _filteredOrders.length;
  }

  Map<String, int> get _statusCounts {
    final counts = <String, int>{
      for (final status in _orderStatuses) status: 0,
    };
    for (final order in _filteredOrders) {
      counts.update(order.status, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  bool _isInSelectedDateRange(DateTime? createdAt) {
    if (createdAt == null) {
      return _fromDate == null && _toDate == null;
    }
    final orderDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (_fromDate != null) {
      final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
      if (orderDate.isBefore(from)) return false;
    }
    if (_toDate != null) {
      final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
      if (orderDate.isAfter(to)) return false;
    }
    return true;
  }

  String _formatMoney(double amount, String currency) {
    final symbol = switch (currency.toUpperCase()) {
      'USD' => '\$',
      'INR' => 'Rs ',
      'EUR' => 'EUR ',
      _ => '${currency.toUpperCase()} ',
    };
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Any time';
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = picked;
      if (_toDate != null && _toDate!.isBefore(picked)) {
        _toDate = picked;
      }
    });
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _toDate = picked);
  }

  void _clearDateRange() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  Future<void> _exportFilteredOrders() async {
    if (_filteredOrders.isEmpty || _isExporting) return;

    setState(() => _isExporting = true);
    try {
      final workbook = excel.Excel.createExcel();
      final ordersSheet = workbook['Orders'];
      final itemsSheet = workbook['Order Items'];
      final defaultSheet = workbook.getDefaultSheet();
      if (defaultSheet != null &&
          defaultSheet != 'Orders' &&
          defaultSheet != 'Order Items') {
        workbook.delete(defaultSheet);
      }

      ordersSheet.appendRow([
        excel.TextCellValue('order_id'),
        excel.TextCellValue('order_code'),
        excel.TextCellValue('customer'),
        excel.TextCellValue('email'),
        excel.TextCellValue('status'),
        excel.TextCellValue('payment_status'),
        excel.TextCellValue('delivery_status'),
        excel.TextCellValue('subtotal'),
        excel.TextCellValue('shipping_fee'),
        excel.TextCellValue('discount_amount'),
        excel.TextCellValue('total_amount'),
        excel.TextCellValue('currency'),
        excel.TextCellValue('item_count'),
        excel.TextCellValue('shipping_address'),
        excel.TextCellValue('notes'),
        excel.TextCellValue('created_at'),
      ]);

      itemsSheet.appendRow([
        excel.TextCellValue('order_id'),
        excel.TextCellValue('order_code'),
        excel.TextCellValue('product_name'),
        excel.TextCellValue('product_title'),
        excel.TextCellValue('unit_price'),
        excel.TextCellValue('quantity'),
        excel.TextCellValue('selected_size'),
        excel.TextCellValue('line_total'),
      ]);

      for (final order in _filteredOrders) {
        ordersSheet.appendRow([
          excel.TextCellValue(order.id),
          excel.TextCellValue(order.orderCode),
          excel.TextCellValue(order.displayCustomerName),
          excel.TextCellValue(order.user?.email ?? ''),
          excel.TextCellValue(order.status),
          excel.TextCellValue(order.paymentStatus),
          excel.TextCellValue(order.deliveryStatus),
          excel.DoubleCellValue(order.subtotal),
          excel.DoubleCellValue(order.shippingFee),
          excel.DoubleCellValue(order.discountAmount),
          excel.DoubleCellValue(order.totalAmount),
          excel.TextCellValue(order.currency),
          excel.IntCellValue(order.itemCount),
          excel.TextCellValue(order.shippingAddress ?? ''),
          excel.TextCellValue(order.notes ?? ''),
          excel.TextCellValue(order.createdAt?.toIso8601String() ?? ''),
        ]);

        for (final item in order.items) {
          itemsSheet.appendRow([
            excel.TextCellValue(order.id),
            excel.TextCellValue(order.orderCode),
            excel.TextCellValue(item.productName),
            excel.TextCellValue(item.productTitle ?? ''),
            excel.DoubleCellValue(item.unitPrice),
            excel.IntCellValue(item.quantity),
            excel.TextCellValue(item.selectedSize?.toString() ?? ''),
            excel.DoubleCellValue(item.lineTotal),
          ]);
        }
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'orders_export_$timestamp.xlsx';

      if (kIsWeb) {
        final bytes = workbook.save(fileName: fileName);
        if (bytes == null) {
          throw 'Could not generate the Excel file.';
        }
      } else {
        final bytes = workbook.save();
        if (bytes == null || bytes.isEmpty) {
          throw 'Could not generate the Excel file.';
        }
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Export orders',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const ['xlsx'],
        );
        if (savePath == null) return;
        await File(savePath).writeAsBytes(bytes, flush: true);
      }

      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text:
            'Exported ${_filteredOrders.length} order${_filteredOrders.length == 1 ? '' : 's'} to Excel.',
        icon: Icons.download_done_rounded,
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
        setState(() => _isExporting = false);
      }
    }
  }

  void _openOrderDetails(AdminOrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.orderCode,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.blackColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Placed by ${order.displayCustomerName}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AdminTag(
                          label: order.status,
                          backgroundColor: _statusBackground(order.status),
                          foregroundColor: _statusColor(order.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView(
                        children: [
                          AdminResponsiveSplit(
                            breakpoint: 920,
                            spacing: 16,
                            primaryFlex: 5,
                            secondaryFlex: 4,
                            primary: _OrderDetailsCard(
                              title: 'Customer and delivery',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailRow(
                                    label: 'Customer',
                                    value: order.displayCustomerName,
                                  ),
                                  _DetailRow(
                                    label: 'Email',
                                    value: order.user?.email ?? 'No email',
                                  ),
                                  _DetailRow(
                                    label: 'Address',
                                    value: order.shippingAddress ??
                                        'No shipping address saved',
                                  ),
                                  _DetailRow(
                                    label: 'Notes',
                                    value: order.notes ?? 'No admin notes',
                                  ),
                                ],
                              ),
                            ),
                            secondary: _OrderDetailsCard(
                              title: 'Payment summary',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailRow(
                                    label: 'Subtotal',
                                    value: _formatMoney(
                                      order.subtotal,
                                      order.currency,
                                    ),
                                  ),
                                  _DetailRow(
                                    label: 'Shipping',
                                    value: _formatMoney(
                                      order.shippingFee,
                                      order.currency,
                                    ),
                                  ),
                                  _DetailRow(
                                    label: 'Discount',
                                    value: _formatMoney(
                                      order.discountAmount,
                                      order.currency,
                                    ),
                                  ),
                                  _DetailRow(
                                    label: 'Total',
                                    value: _formatMoney(
                                      order.totalAmount,
                                      order.currency,
                                    ),
                                    isEmphasized: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _OrderDetailsCard(
                            title:
                                'Items (${order.itemCount} item${order.itemCount == 1 ? '' : 's'})',
                            child: Column(
                              children: order.items.isEmpty
                                  ? const [
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          'No order items were found for this order.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.hintColor,
                                          ),
                                        ),
                                      ),
                                    ]
                                  : order.items
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: _OrderItemTile(
                                              item: item,
                                              formatMoney: (amount) =>
                                                  _formatMoney(
                                                    amount,
                                                    order.currency,
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
      case 'delivered':
        return const Color(0xFF1E8E5A);
      case 'processing':
      case 'packed':
      case 'shipped':
        return const Color(0xFF2558C5);
      case 'cancelled':
      case 'failed':
      case 'refunded':
        return Colors.red;
      default:
        return const Color(0xFFB06A00);
    }
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
      case 'delivered':
        return const Color(0xFFE8F7ED);
      case 'processing':
      case 'packed':
      case 'shipped':
        return const Color(0xFFE7F0FF);
      case 'cancelled':
      case 'failed':
      case 'refunded':
        return const Color(0xFFFFE4E6);
      default:
        return const Color(0xFFFFF2D8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.redColor,
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
        children: [
          AdminResponsiveSplit(
            breakpoint: 1120,
            spacing: 20,
            primaryFlex: 7,
            secondaryFlex: 4,
            primary: _buildSummarySection(),
            secondary: _buildOpsGuideCard(),
          ),
          const SizedBox(height: 20),
          _buildAnalyticsSection(),
          const SizedBox(height: 20),
          _buildOrdersPanel(),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.redColor),
              ),
            )
          else if (_orders.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              description:
                  'Once customers start checking out, your order operations will show up here for review and status updates.',
            )
          else if (_filteredOrders.isEmpty)
            const AdminEmptyPanel(
              icon: Icons.search_off_rounded,
              title: 'No matching orders',
              description:
                  'Try adjusting the search, status, payment, delivery, or date filters.',
            )
          else
            ..._filteredOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _OrderCard(
                  order: order,
                  isUpdating: _updatingOrderId == order.id,
                  orderStatuses: _orderStatuses,
                  paymentStatuses: _paymentStatuses,
                  deliveryStatuses: _deliveryStatuses,
                  formatMoney: (amount) =>
                      _formatMoney(amount, order.currency),
                  statusColor: _statusColor,
                  statusBackground: _statusBackground,
                  onStatusChanged: (value) =>
                      _updateOrderStatus(order: order, status: value),
                  onPaymentStatusChanged: (value) => _updateOrderStatus(
                    order: order,
                    paymentStatus: value,
                  ),
                  onDeliveryStatusChanged: (value) => _updateOrderStatus(
                    order: order,
                    deliveryStatus: value,
                  ),
                  onViewDetails: () => _openOrderDetails(order),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final currency = _filteredOrders.isEmpty
        ? (_orders.isEmpty ? 'USD' : _orders.first.currency)
        : _filteredOrders.first.currency;

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
              value: '${_filteredOrders.length}',
              accentColor: AppColors.redColor,
            ),
            _OrderMetricCard(
              icon: Icons.hourglass_top_rounded,
              label: 'Pending review',
              value: '$_pendingOrdersCount',
              accentColor: const Color(0xFFB06A00),
            ),
            _OrderMetricCard(
              icon: Icons.local_shipping_outlined,
              label: 'Open delivery queue',
              value: '$_deliveryQueueCount',
              accentColor: const Color(0xFF2558C5),
            ),
            _OrderMetricCard(
              icon: Icons.payments_outlined,
              label: 'Visible revenue',
              value: _formatMoney(_filteredRevenue, currency),
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

  Widget _buildAnalyticsSection() {
    final currency = _filteredOrders.isEmpty
        ? (_orders.isEmpty ? 'USD' : _orders.first.currency)
        : _filteredOrders.first.currency;

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
                  value: _formatMoney(_paidRevenue, currency),
                ),
                _AnalyticsChip(
                  label: 'Avg order value',
                  value: _formatMoney(_averageOrderValue, currency),
                ),
                _AnalyticsChip(
                  label: 'Completion rate',
                  value: '${(_completionRate * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 18),
            ..._orderStatuses.map(
              (status) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AnalyticsBar(
                  label: status,
                  value: _statusCounts[status] ?? 0,
                  total: _filteredOrders.length,
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
                  onPressed:
                      _filteredOrders.isEmpty || _isExporting
                          ? null
                          : _exportFilteredOrders,
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

  Widget _buildOrdersPanel() {
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
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: _inputDecoration('Search orders').copyWith(
              hintText: 'Search by order, customer, address, or amount',
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          if (!_isLoading && _orders.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${_filteredOrders.length} order${_filteredOrders.length == 1 ? '' : 's'} shown. $_processingOrdersCount currently in processing.',
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

class _OrderMetricCard extends StatelessWidget {
  const _OrderMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: AdminSurfaceCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.blackColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsChip extends StatelessWidget {
  const _AnalyticsChip({required this.label, required this.value});

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
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsBar extends StatelessWidget {
  const _AnalyticsBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final widthFactor = total == 0 ? 0.0 : value / total;
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
              '$value',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
                  width: constraints.maxWidth * widthFactor,
                  decoration: BoxDecoration(
                    color: color,
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

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blackColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.$1,
              child: Text(item.$2),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isUpdating,
    required this.orderStatuses,
    required this.paymentStatuses,
    required this.deliveryStatuses,
    required this.formatMoney,
    required this.statusColor,
    required this.statusBackground,
    required this.onStatusChanged,
    required this.onPaymentStatusChanged,
    required this.onDeliveryStatusChanged,
    required this.onViewDetails,
  });

  final AdminOrderModel order;
  final bool isUpdating;
  final List<String> orderStatuses;
  final List<String> paymentStatuses;
  final List<String> deliveryStatuses;
  final String Function(double amount) formatMoney;
  final Color Function(String value) statusColor;
  final Color Function(String value) statusBackground;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPaymentStatusChanged;
  final ValueChanged<String?> onDeliveryStatusChanged;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final placedLabel = order.createdAt == null
        ? 'Unknown date'
        : '${order.createdAt!.year}-${order.createdAt!.month.toString().padLeft(2, '0')}-${order.createdAt!.day.toString().padLeft(2, '0')}';

    return AdminSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderCode,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blackColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.displayCustomerName} - $placedLabel',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.hintColor,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUpdating)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.redColor,
                        ),
                      ),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: onViewDetails,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: AppColors.blackColor,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Details'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminTag(
                label: order.status,
                backgroundColor: statusBackground(order.status),
                foregroundColor: statusColor(order.status),
                isCompact: true,
              ),
              AdminTag(
                label: order.paymentStatus,
                backgroundColor: statusBackground(order.paymentStatus),
                foregroundColor: statusColor(order.paymentStatus),
                isCompact: true,
              ),
              AdminTag(
                label: order.deliveryStatus,
                backgroundColor: statusBackground(order.deliveryStatus),
                foregroundColor: statusColor(order.deliveryStatus),
                isCompact: true,
              ),
              AdminTag(
                label:
                    '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              final controls = [
                _StatusDropdown(
                  label: 'Order',
                  value: order.status,
                  items: orderStatuses,
                  onChanged: isUpdating ? null : onStatusChanged,
                ),
                _StatusDropdown(
                  label: 'Payment',
                  value: order.paymentStatus,
                  items: paymentStatuses,
                  onChanged: isUpdating ? null : onPaymentStatusChanged,
                ),
                _StatusDropdown(
                  label: 'Delivery',
                  value: order.deliveryStatus,
                  items: deliveryStatuses,
                  onChanged: isUpdating ? null : onDeliveryStatusChanged,
                ),
              ];

              if (!isWide) {
                return Column(
                  children: [
                    ...controls.map(
                      (control) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: control,
                      ),
                    ),
                    _OrderAmountSummary(
                      totalLabel: formatMoney(order.totalAmount),
                      helperLabel:
                          'Subtotal ${formatMoney(order.subtotal)} - Discount ${formatMoney(order.discountAmount)}',
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: controls[0]),
                  const SizedBox(width: 12),
                  Expanded(child: controls[1]),
                  const SizedBox(width: 12),
                  Expanded(child: controls[2]),
                  const SizedBox(width: 18),
                  _OrderAmountSummary(
                    totalLabel: formatMoney(order.totalAmount),
                    helperLabel:
                        'Subtotal ${formatMoney(order.subtotal)} - Discount ${formatMoney(order.discountAmount)}',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _OrderAmountSummary extends StatelessWidget {
  const _OrderAmountSummary({
    required this.totalLabel,
    required this.helperLabel,
  });

  final String totalLabel;
  final String helperLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.blackColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totalLabel,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helperLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFD6D6D6),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailsCard extends StatelessWidget {
  const _OrderDetailsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isEmphasized ? 18 : 14,
              fontWeight: isEmphasized ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.blackColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({
    required this.item,
    required this.formatMoney,
  });

  final AdminOrderItemModel item;
  final String Function(double amount) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 82,
              width: 82,
              child: item.productImageUrl?.isNotEmpty == true
                  ? Image.network(
                      item.productImageUrl!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.grayColor,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.white,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.grayColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
                if ((item.productTitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.productTitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.hintColor,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminTag(label: 'Qty ${item.quantity}', isCompact: true),
                    if (item.selectedSize != null)
                      AdminTag(
                        label: 'Size ${item.selectedSize}',
                        isCompact: true,
                      ),
                    AdminTag(
                      label: formatMoney(item.unitPrice),
                      isCompact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatMoney(item.lineTotal),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidePoint extends StatelessWidget {
  const _GuidePoint({required this.title, required this.description});

  final String title;
  final String description;

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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFFD5D5D5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
