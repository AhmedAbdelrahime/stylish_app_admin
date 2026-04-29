import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungry/core/api/supabase_error_mapper.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/admin/data/admin_order_model.dart';
import 'package:hungry/pages/admin/logic/order/cubit/admin_order_cubit.dart';
import 'package:hungry/pages/admin/logic/order/cubit/admin_order_state.dart';
import 'package:hungry/pages/admin/widgets/admin_shell_widgets.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
part 'admin_order_data_actions.dart';
part 'admin_order_filter_helpers.dart';
part 'admin_order_export_actions.dart';
part 'admin_order_details_sheet.dart';
part 'admin_order_screen_sections.dart';
part 'admin_order_metric_widgets.dart';
part 'admin_order_card.dart';
part 'admin_order_details_widgets.dart';
part 'admin_order_guide_widgets.dart';

class AdminOrderScreen extends StatelessWidget {
  const AdminOrderScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminOrderCubit(),
      child: const _AdminOrderView(),
    );
  }
}

class _AdminOrderView extends StatefulWidget {
  const _AdminOrderView();
  @override
  State<_AdminOrderView> createState() => _AdminOrderViewState();
}

class _AdminOrderViewState extends State<_AdminOrderView> {
  static const _orderStatuses = [
    'pending',
    'processing',
    'completed',
    'cancelled',
  ];
  static const _paymentStatuses = ['pending', 'paid', 'refunded', 'failed'];
  static const _deliveryStatuses = [
    'pending',
    'packed',
    'shipped',
    'delivered',
  ];
  final TextEditingController _searchController = TextEditingController();
  bool _isExporting = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _paymentFilter = 'all';
  String _deliveryFilter = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;
  Timer? _searchDebounce;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadOrders();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminOrderCubit, AdminOrderState>(
      builder: (context, orderState) {
        final filteredOrders = _filterOrders(orderState.orders);
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
                primary: _buildSummarySection(
                  orderState.orders,
                  filteredOrders,
                ),
                secondary: _buildOpsGuideCard(),
              ),
              const SizedBox(height: 20),
              _buildAnalyticsSection(orderState.orders, filteredOrders),
              const SizedBox(height: 20),
              _buildOrdersPanel(orderState.orders, filteredOrders),
              const SizedBox(height: 16),
              if (orderState.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.redColor),
                  ),
                )
              else if (orderState.orders.isEmpty)
                const AdminEmptyPanel(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet',
                  description:
                      'Once customers start checking out, your order operations will show up here for review and status updates.',
                )
              else if (filteredOrders.isEmpty)
                const AdminEmptyPanel(
                  icon: Icons.search_off_rounded,
                  title: 'No matching orders',
                  description:
                      'Try adjusting the search, status, payment, delivery, or date filters.',
                )
              else
                ...filteredOrders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _OrderCard(
                      order: order,
                      isUpdating: orderState.updatingOrderId == order.id,
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
      },
    );
  }
}
