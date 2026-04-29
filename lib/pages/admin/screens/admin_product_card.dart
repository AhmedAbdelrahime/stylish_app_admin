part of 'admin_product_screen.dart';

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductModel product;
  final String categoryName;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.7,
                  child: Image.network(
                    product.primaryImage,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryColor,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.grayColor,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    child: Checkbox(
                      value: isSelected,
                      visualDensity: VisualDensity.compact,
                      onChanged: (value) => onSelectionChanged(value ?? false),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminTag(label: categoryName, isCompact: true),
                    AdminTag(label: product.status, isCompact: true),
                    AdminTag(
                      label: product.isInStock
                          ? '${product.stockQuantity} in stock'
                          : 'Out of stock',
                      backgroundColor: product.isInStock
                          ? const Color(0xFFE8F7ED)
                          : const Color(0xFFFFE4E6),
                      foregroundColor: product.isInStock
                          ? const Color(0xFF1E8E5A)
                          : Colors.red,
                      isCompact: true,
                    ),
                    if (product.featured)
                      const AdminTag(
                        label: 'Featured',
                        backgroundColor: Color(0xFFE7F0FF),
                        foregroundColor: Color(0xFF2558C5),
                        isCompact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${product.effectivePrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.blackColor,
                            ),
                          ),
                          if (product.hasSale)
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.hintColor,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 19),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      color: Colors.red,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 19),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
