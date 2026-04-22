import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/shared/custom_text.dart';

class PrivacyItem {
  final String text;
  final IconData icon;

  const PrivacyItem({required this.text, required this.icon});
}

const List<PrivacyItem> privacyItems = [
  PrivacyItem(text: 'Refund Policy', icon: Icons.lock),
  PrivacyItem(text: 'Return Policy', icon: Icons.local_shipping),
  PrivacyItem(text: 'Terms', icon: Icons.description),
];

class PolicyWidget extends StatelessWidget {
  const PolicyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        privacyItems.length,
        (index) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.grayColor),
          ),
          margin: const EdgeInsets.only(right: 7),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: Row(
            children: [
              Icon(privacyItems[index].icon, color: AppColors.hintColor),
              const Gap(2),
              CustomText(
                text: privacyItems[index].text,
                size: 12,
                weight: FontWeight.w400,
                color: AppColors.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
