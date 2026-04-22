import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';

class HomeFilterSection extends StatelessWidget {
  const HomeFilterSection({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blackColor,
                  ),
                ),
                const Gap(4),
                const Text(
                  'Refined collections with a cleaner storefront layout.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.hintColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          const _FilterChip(label: 'Sort', assetPath: 'assets/svgs/sort.svg'),
          const Gap(8),
          const _FilterChip(
            label: 'Filter',
            assetPath: 'assets/svgs/filter.svg',
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.assetPath});

  final String label;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.blackColor,
            ),
          ),
          const Gap(8),
          SvgPicture.asset(assetPath, height: 16),
        ],
      ),
    );
  }
}
