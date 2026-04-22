import 'package:flutter/material.dart';
import 'package:hungry/pages/cart/widgets/cart_btn.dart';
import 'package:hungry/shared/custom_text.dart';

class CustomBtnSheet extends StatelessWidget {
  const CustomBtnSheet({
    super.key,
    required this.total,
    required this.discountAmount,
    required this.onProceed,
  });

  final double total;
  final double discountAmount;
  final VoidCallback onProceed;

  String get _formattedTotal {
    if (total == total.roundToDouble()) {
      return total.toStringAsFixed(0);
    }

    return total.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade600,
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      height: 110,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: '\u20B9$_formattedTotal',
                  color: Colors.black,
                  weight: FontWeight.bold,
                  size: 24,
                ),
                CustomText(
                  text: discountAmount > 0
                      ? 'Discount included in total'
                      : 'Includes shipping charges',
                  color: Colors.red,
                  weight: FontWeight.w500,
                  size: 13,
                ),
              ],
            ),
            const Spacer(),
            CartBtn(ontap: onProceed, text: 'Proceed to Payment'),
          ],
        ),
      ),
    );
  }
}
