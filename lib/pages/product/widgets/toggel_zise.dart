import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/home/models/product_model.dart';
import 'package:hungry/shared/custom_text.dart';

class ToggelSize extends StatelessWidget {
  const ToggelSize({
    super.key,
    required this.product,
    required this.selectedSize,
    required this.onChanged,
  });

  final ProductModel product;
  final int? selectedSize;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (product.sizes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: 'Size: ${selectedSize ?? product.sizes.first} UK',
            size: 14,
            weight: FontWeight.w600,
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: product.sizes.map((size) {
              final isSelected = selectedSize == size;

              return GestureDetector(
                onTap: () => onChanged(size),
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.redColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      width: 1.5,
                      color: isSelected
                          ? AppColors.redColor
                          : AppColors.grayColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: CustomText(
                    text: '$size UK',
                    size: 14,
                    weight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.blackColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
