part of 'admin_promotion_screen.dart';

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final AdminCouponModel coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDanger = coupon.isExpired || !coupon.isActive;

    return AdminSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  coupon.code,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
              ),
              AdminTag(
                label: coupon.isActive ? 'Active' : 'Inactive',
                backgroundColor: isDanger
                    ? const Color(0xFFFFE4E6)
                    : const Color(0xFFE8F7ED),
                foregroundColor: isDanger
                    ? Colors.red
                    : const Color(0xFF1E8E5A),
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            coupon.description ?? 'No description',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminTag(
                label: '${coupon.discountValue} ${coupon.discountType}',
                isCompact: true,
              ),
              AdminTag(label: 'Used ${coupon.usedCount}', isCompact: true),
              AdminTag(label: 'Min ${coupon.minOrderAmount}', isCompact: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: onToggle,
                tooltip: coupon.isActive ? 'Deactivate' : 'Activate',
                icon: Icon(
                  coupon.isActive
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete',
                color: Colors.red,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final AdminBannerModel banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: AspectRatio(
              aspectRatio: 1.9,
              child: Image.network(
                banner.imageUrl,
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  banner.subtitle ?? 'No subtitle',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminTag(
                      label: banner.isActive ? 'Active' : 'Inactive',
                      isCompact: true,
                    ),
                    AdminTag(label: banner.targetType, isCompact: true),
                    AdminTag(
                      label: 'Sort ${banner.sortOrder}',
                      isCompact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  banner.targetValue ?? 'No target value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: onMoveUp,
                      tooltip: 'Move up',
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                    IconButton(
                      onPressed: onMoveDown,
                      tooltip: 'Move down',
                      icon: const Icon(Icons.arrow_downward_rounded),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      color: Colors.red,
                      icon: const Icon(Icons.delete_outline),
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminOfferModel offer;
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
            child: AspectRatio(
              aspectRatio: 1.8,
              child: Image.network(
                offer.imageUrl,
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title ?? 'Untitled offer',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.imageUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      color: Colors.red,
                      icon: const Icon(Icons.delete_outline),
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
