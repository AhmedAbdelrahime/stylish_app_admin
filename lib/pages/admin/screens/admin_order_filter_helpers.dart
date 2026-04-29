// ignore_for_file: invalid_use_of_protected_member

part of 'admin_order_screen.dart';

extension _AdminOrderFilterHelpers on _AdminOrderViewState {
  List<AdminOrderModel> _filterOrders(List<AdminOrderModel> orders) {
    final query = _searchQuery.trim().toLowerCase();
    return orders.where((order) {
      if (_statusFilter != 'all' && order.status != _statusFilter) {
        return false;
      }
      if (_paymentFilter != 'all' && order.paymentStatus != _paymentFilter) {
        return false;
      }
      if (_deliveryFilter != 'all' && order.deliveryStatus != _deliveryFilter) {
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

  double _filteredRevenue(List<AdminOrderModel> filteredOrders) =>
      filteredOrders.fold<double>(0, (sum, order) => sum + order.totalAmount);
  double _paidRevenue(List<AdminOrderModel> filteredOrders) => filteredOrders
      .where((order) => order.paymentStatus == 'paid')
      .fold<double>(0, (sum, order) => sum + order.totalAmount);
  int _pendingOrdersCount(List<AdminOrderModel> filteredOrders) =>
      filteredOrders.where((order) => order.status == 'pending').length;
  int _processingOrdersCount(List<AdminOrderModel> filteredOrders) =>
      filteredOrders.where((order) => order.status == 'processing').length;
  int _deliveryQueueCount(List<AdminOrderModel> filteredOrders) =>
      filteredOrders
          .where((order) => order.deliveryStatus != 'delivered')
          .length;
  double _averageOrderValue(List<AdminOrderModel> filteredOrders) {
    if (filteredOrders.isEmpty) return 0;
    return _filteredRevenue(filteredOrders) / filteredOrders.length;
  }

  double _completionRate(List<AdminOrderModel> filteredOrders) {
    if (filteredOrders.isEmpty) return 0;
    final completedCount = filteredOrders
        .where((order) => order.status == 'completed')
        .length;
    return completedCount / filteredOrders.length;
  }

  Map<String, int> _statusCounts(List<AdminOrderModel> filteredOrders) {
    final counts = <String, int>{
      for (final status in _AdminOrderViewState._orderStatuses) status: 0,
    };
    for (final order in filteredOrders) {
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
}
