import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/cart/data/cart_item_model.dart';

class ShppingCard extends StatelessWidget {
  const ShppingCard({
    super.key,
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
    this.isUpdating = false,
  });

  final CartItemModel item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;
  final bool isUpdating;

  String _price(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final canIncrease = item.isInStock && item.quantity < item.stockQuantity;
    final stockLabel = !item.isInStock
        ? 'Out of stock'
        : item.isLowStock
        ? 'Only ${item.stockQuantity} left'
        : 'In stock';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductImage(imagePath: item.imagePath),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blackColor,
                        ),
                      ),
                      if (item.productTitle.trim().isNotEmpty) ...[
                        const Gap(4),
                        Text(
                          item.productTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.hintColor.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                      const Gap(10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (item.size != null)
                            _MetaChip(label: 'Size ${item.size}'),
                          if (item.color != null &&
                              item.color!.trim().isNotEmpty)
                            _MetaChip(label: item.color!.trim()),
                          _MetaChip(
                            label: stockLabel,
                            foregroundColor: item.isInStock
                                ? Colors.green.shade700
                                : AppColors.redColor,
                            borderColor: item.isInStock
                                ? Colors.green.shade100
                                : AppColors.redColor.withValues(alpha: 0.18),
                          ),
                        ],
                      ),
                      const Gap(10),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: item.rating.clamp(0, 5).toDouble(),
                            itemBuilder: (_, __) =>
                                const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 15,
                          ),
                          const Gap(6),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.hintColor.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(14),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${_price(item.price)}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blackColor,
                      ),
                    ),
                    if (item.hasDiscount) ...[
                      const Gap(2),
                      Row(
                        children: [
                          Text(
                            '₹${_price(item.originalPrice ?? item.price)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.grayColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            '${item.discountPercentage}% off',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.redColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                _QuantityControl(
                  quantity: item.quantity,
                  canIncrease: canIncrease,
                  isUpdating: isUpdating,
                  onDecrease: onDecrease,
                  onIncrease: onIncrease,
                ),
              ],
            ),
            const Gap(12),
            Divider(color: Colors.black.withValues(alpha: 0.08)),
            const Gap(10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: isUpdating ? null : onRemove,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.redColor,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),
                Text(
                  'Line total',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.hintColor.withValues(alpha: 0.9),
                  ),
                ),
                const Gap(10),
                Text(
                  '₹${_price(item.lineTotal)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: 104,
      width: 104,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.hintColor.withValues(alpha: 0.65),
      ),
    );

    if (imagePath.trim().isEmpty) {
      return fallback;
    }

    final isNetwork = imagePath.startsWith('http');
    final image = isNetwork
        ? Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          )
        : Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(height: 104, width: 104, child: image),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.foregroundColor = AppColors.blackColor,
    this.borderColor,
  });

  final String label;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.canIncrease,
    required this.isUpdating,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool canIncrease;
  final bool isUpdating;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(icon: Icons.remove, onTap: isUpdating ? null : onDecrease),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: isUpdating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.redColor,
                    ),
                  )
                : Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blackColor,
                    ),
                  ),
          ),
          _QtyButton(
            icon: Icons.add,
            onTap: isUpdating || !canIncrease ? null : onIncrease,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: onTap == null
              ? Colors.black.withValues(alpha: 0.04)
              : Colors.white,
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.grayColor : AppColors.blackColor,
        ),
      ),
    );
  }
}
