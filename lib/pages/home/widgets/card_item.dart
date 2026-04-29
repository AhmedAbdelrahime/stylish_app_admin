import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/home/logic/favorites/favorites_controller.dart';
import 'package:hungry/pages/home/models/product_model.dart';

class CardItem extends StatelessWidget {
  const CardItem({
    super.key,
    required this.product,
    required this.relatedProducts,
    this.margin = const EdgeInsets.only(right: 16),
  });

  final ProductModel product;
  final List<ProductModel> relatedProducts;
  final EdgeInsetsGeometry margin;
  static final FavoritesController _favorites = FavoritesController.instance;

  String get _formattedPrice {
    final price = product.effectivePrice;

    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }

    return price.toStringAsFixed(2);
  }

  List<_ProductBadgeData> get _badges {
    final badges = <_ProductBadgeData>[];

    if (product.featured) {
      badges.add(
        const _ProductBadgeData(
          label: 'Featured',
          backgroundColor: Color(0xFFE8F7ED),
          foregroundColor: Color(0xFF1E8E5A),
        ),
      );
    }

    if (product.hasSale) {
      badges.add(
        const _ProductBadgeData(
          label: 'Sale',
          backgroundColor: Color(0xFFFFF2D9),
          foregroundColor: Color(0xFFB7791F),
        ),
      );
    } else if (product.rating >= 4.5) {
      badges.add(
        const _ProductBadgeData(
          label: 'Top Rated',
          backgroundColor: Color(0xFFFFF2D9),
          foregroundColor: Color(0xFFB7791F),
        ),
      );
    }

    if (product.isLowStock) {
      badges.add(
        const _ProductBadgeData(
          label: 'Low Stock',
          backgroundColor: Color(0xFFFFE8EC),
          foregroundColor: Color(0xFFB4233C),
        ),
      );
    }

    return badges.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        clipBehavior: Clip.antiAlias,
        width: 176,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.network(
                    product.primaryImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade300),
                  ),
                ),
                if (_badges.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _badges
                          .map(
                            (badge) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _BadgePill(badge: badge),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: AnimatedBuilder(
                    animation: _favorites,
                    builder: (context, _) {
                      final isFavorite = _favorites.isFavorite(product.id);

                      return Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _favorites.toggle(product.id),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: isFavorite
                                  ? AppColors.redColor
                                  : AppColors.blackColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blackColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.hintColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\u20B9$_formattedPrice',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blackColor,
                          ),
                        ),
                        if (product.hasSale) ...[
                          const SizedBox(height: 3),
                          Text(
                            '\u20B9${product.price.toStringAsFixed(product.price == product.price.roundToDouble() ? 0 : 2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.hintColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (index) => Padding(
                                padding: const EdgeInsets.only(right: 1),
                                child: Icon(
                                  index < product.rating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 14,
                                  color: const Color(0xFFFFC120),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.badge});

  final _ProductBadgeData badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badge.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: badge.foregroundColor,
        ),
      ),
    );
  }
}

class _ProductBadgeData {
  const _ProductBadgeData({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
}
