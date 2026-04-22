import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/cart/widgets/cart_btn.dart';
import 'package:hungry/shared/custom_text.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key, this.isDeleteCard = false});
  final bool? isDeleteCard;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              isDeleteCard ?? false
                  ? 'assets/svgs/deleteCard.svg'
                  : 'assets/svgs/logout.svg',
              colorFilter: const ColorFilter.mode(
                AppColors.redColor,
                BlendMode.srcIn,
              ),
              height: 60,
            ),
            const Gap(16),
            CustomText(
              text: isDeleteCard ?? false
                  ? 'Are you sure you want to delete this card?'
                  : 'Are you sure you want to logout?',
              size: 16,
              weight: FontWeight.w500,
            ),
            const Gap(24),

            Row(
              children: [
                Expanded(
                  child: CartBtn(
                    text: 'Go Back',
                    ontap: () => Navigator.pop(context, false),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: CartBtn(
                    textcolor: AppColors.redColor,
                    text: isDeleteCard ?? false ? 'Delete' : 'Logout',
                    color: AppColors.primaryColor,
                    ontap: () => Navigator.pop(context, true),
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
