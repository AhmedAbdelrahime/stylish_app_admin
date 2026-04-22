import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';

class DelevaryWidget extends StatelessWidget {
  const DelevaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grayColor.withValues(alpha: 0.2)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.blackColor,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Standard delivery in 1 to 3 business days. Tracking details appear after checkout.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.hintColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
