import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/shared/custom_text.dart';

class AddressSection extends StatelessWidget {
  const AddressSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset('assets/svgs/location.svg'),
            const SizedBox(width: 10),
            CustomText(
              text: 'Delivery Address',
              size: 16,
              weight: FontWeight.w600,
            ),
          ],
        ),
        Gap(10),

        Row(
          children: [
            Material(
              color: Colors.transparent,
              elevation: 5,
              borderRadius: BorderRadius.circular(8),

              child: Flexible(
                flex: 4,
                child: Container(
                  height: 90,

                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: [
                              CustomText(
                                text: 'Address:',
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                              Gap(170),
                              SvgPicture.asset('assets/svgs/edit.svg'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      CustomText(
                        text: '216 St Paul\'s Rd, London N1 2LL,UK ',
                        size: 14,
                        weight: FontWeight.w400,
                        color: AppColors.blackColor,
                      ),
                      CustomText(
                        text: 'Contact :  +44-784232',
                        size: 14,
                        weight: FontWeight.w400,
                        color: AppColors.blackColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 1,
              child: Material(
                color: Colors.transparent,
                elevation: 5,
                borderRadius: BorderRadius.circular(8),

                child: Container(
                  width: double.infinity,
                  height: 90,

                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.blackColor,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.add, color: AppColors.blackColor),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
