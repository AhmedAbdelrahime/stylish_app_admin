import 'package:flutter/material.dart';
import 'package:hungry/shared/custom_text.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.text1, required this.text2});
  final String text1;
  final String text2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(text: text1, size: 30, weight: FontWeight.bold),
        CustomText(text: text2, size: 30, weight: FontWeight.bold),
      ],
    );
  }
}
