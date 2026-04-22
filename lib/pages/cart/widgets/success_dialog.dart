import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/shared/custom_text.dart';

class SuccessDialog extends StatelessWidget {
  const SuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),

          color: AppColors.primaryColor,
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/svgs/success.svg'),
            Gap(10),
            Center(
              child: CustomText(
                text: 'Payment done successfully.',
                color: Colors.black,
                weight: FontWeight.w500,
                size: 16,
              ),
            ),
            Gap(20),
            // CartBtn(
            //   width: double.infinity,
            //   ontap: () => Navigator.pop(context),
            //   text: 'Go Back',
            // ),
          ],
        ),
      ),
    );
  }
}
