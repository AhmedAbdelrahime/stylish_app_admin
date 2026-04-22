import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/shared/custom_text.dart';

class CustomBottomsheet extends StatelessWidget {
  const CustomBottomsheet({
    super.key,
    required this.isloadingUpdate,
    required this.upadateProfileData,
  });

  final bool isloadingUpdate;
  final VoidCallback upadateProfileData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      height: 80,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -8),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: AppColors.primaryColor,
      ),
      child: isloadingUpdate
          ? const Center(
              child: CupertinoActivityIndicator(
                color: AppColors.redColor,
                radius: 20,
              ),
            )
          : GestureDetector(
              onTap: upadateProfileData,
              child: Center(
                child: Container(
                  height: 60,
                  width: 170,
                  decoration: BoxDecoration(
                    color: AppColors.redColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryColor, width: 3),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        text: 'update Profile ',
                        color: AppColors.primaryColor,
                        weight: FontWeight.w600,
                        size: 18,
                      ),
                      Icon(Icons.edit, color: AppColors.primaryColor, size: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
