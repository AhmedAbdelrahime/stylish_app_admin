import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/settings/view/add_pyment_card.dart';
import 'package:hungry/shared/custom_text.dart';

class AddCardButton extends StatelessWidget {
  const AddCardButton({super.key, this.onCardAdded});

  final Future<void> Function()? onCardAdded;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final added = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const AddPaymentCard()),
        );

        if (added == true) {
          await onCardAdded?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.grayColor.withValues(alpha: .2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              text: 'Add Card',
              size: 18,
              weight: FontWeight.w600,
              color: AppColors.blackColor.withValues(alpha: .8),
            ),
            const Gap(10),
            Icon(
              Icons.payment_outlined,
              color: AppColors.blackColor.withValues(alpha: .8),
            ),
          ],
        ),
      ),
    );
  }
}
