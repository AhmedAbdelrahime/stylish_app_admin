import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';

class ProductBotton extends StatelessWidget {
  const ProductBotton({
    super.key,
    required this.price,
    required this.selectedSize,
    required this.onGoToCart,
    required this.onBuyNow,
  });

  final double price;
  final int? selectedSize;
  final VoidCallback onGoToCart;
  final VoidCallback onBuyNow;

  String get _formattedPrice {
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }

    return price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\u20B9$_formattedPrice',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blackColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedSize == null
                              ? 'Ready to add this item'
                              : 'Selected size: $selectedSize UK',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onGoToCart,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blackColor,
                        side: const BorderSide(color: AppColors.blackColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onBuyNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.redColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
