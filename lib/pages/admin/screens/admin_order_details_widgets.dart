part of 'admin_order_screen.dart';

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
  const _OrderItemTile({required this.item, required this.formatMoney});

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
