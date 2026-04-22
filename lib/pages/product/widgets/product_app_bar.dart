import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/shared/custom_text.dart';

class ProductAppBar extends StatelessWidget {
  const ProductAppBar({
    super.key,
    this.text,
    this.padiing,
    this.showbackicon = true,
    this.isSettingpage = false,
    this.logout,
    this.onActionTap,
  });

  final String? text;
  final double? padiing;
  final bool? showbackicon;
  final bool? isSettingpage;
  final VoidCallback? logout;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: padiing ?? 20,
        right: padiing ?? 20,
        top: 50,
        bottom: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: showbackicon == true
                ? () {
                    Navigator.maybePop(context);
                  }
                : null,
            child: showbackicon == true
                ? const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.hintColor,
                  )
                : const SizedBox(width: 70),
          ),
          CustomText(text: text ?? '', size: 22, weight: FontWeight.w500),
          if (text == null)
            GestureDetector(
              onTap: onActionTap,
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.hintColor,
              ),
            )
          else if (isSettingpage == true)
            GestureDetector(
              onTap: logout,
              child: Row(
                children: [
                  SvgPicture.asset('assets/svgs/logout.svg'),
                  const Gap(5),
                  CustomText(text: 'Logout', size: 16, weight: FontWeight.w400),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
