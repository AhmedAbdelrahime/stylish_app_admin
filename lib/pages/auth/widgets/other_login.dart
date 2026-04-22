import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/auth/models/loogin_icons.dart';
import 'package:hungry/shared/custom_text.dart';

class OtherLogin extends StatelessWidget {
  const OtherLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Gap(50),
        CustomText(
          text: '- OR Continue with -',
          size: 14,
          weight: FontWeight.w500,
          color: AppColors.hintColor,
        ),
        Gap(20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            icons.length,
            (index) => GestureDetector(
              onTap: icons[index].ontap,

              child: Container(
                margin: EdgeInsets.all(5),
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.redColor,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 255, 240, 240),
                  radius: 20,
                  child: Image.asset(icons[index].imge, width: 30),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
