// ignore_for_file: invalid_use_of_protected_member

part of 'admin_order_screen.dart';

extension _AdminOrderDetailsSheet on _AdminOrderViewState {
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
                                    value:
                                        order.shippingAddress ??
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
}
