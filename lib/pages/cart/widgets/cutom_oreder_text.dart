import 'package:flutter/material.dart';
import 'package:hungry/shared/custom_text.dart';

class CustomOrederText extends StatelessWidget {
  const CustomOrederText({
    super.key,
    this.color,
    required this.text,
    required this.price,
  });
  final Color? color;
  final String text;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: text, size: 18, weight: FontWeight.w400, color: color),
        CustomText(
          text: '\$ $price',
          size: 18,
          weight: FontWeight.w400,
          color: color,
        ),
      ],
    );
  }
}
