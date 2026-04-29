part of 'admin_order_screen.dart';

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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFFD6D6D6)),
          ),
        ],
      ),
    );
  }
}
