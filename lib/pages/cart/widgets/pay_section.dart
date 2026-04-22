import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/shared/custom_text.dart';

class PaySection extends StatelessWidget {
  const PaySection({
    super.key,
    required this.subtotal,
    required this.shippingFee,
    required this.discountAmount,
    required this.total,
    required this.couponController,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
    required this.isApplyingCoupon,
    this.couponMessage,
    this.appliedCouponCode,
  });

  final double subtotal;
  final double shippingFee;
  final double discountAmount;
  final double total;
  final TextEditingController couponController;
  final VoidCallback onApplyCoupon;
  final VoidCallback onRemoveCoupon;
  final bool isApplyingCoupon;
  final String? couponMessage;
  final String? appliedCouponCode;

  String _price(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/svgs/coupon.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.blackColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  const Gap(10),
                  CustomText(
                    text: appliedCouponCode == null
                        ? 'Apply Coupon'
                        : 'Coupon Applied',
                    size: 16,
                    weight: FontWeight.w600,
                  ),
                  const Spacer(),
                  if (appliedCouponCode != null)
                    GestureDetector(
                      onTap: onRemoveCoupon,
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.hintColor,
                        size: 18,
                      ),
                    ),
                ],
              ),
              const Gap(14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        filled: true,
                        fillColor: AppColors.primaryColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isApplyingCoupon ? null : onApplyCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.redColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isApplyingCoupon
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Apply',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
              if (couponMessage != null) ...[
                const Gap(10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    couponMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: appliedCouponCode == null
                          ? Colors.orange.shade800
                          : const Color(0xFF1E8E5A),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Gap(20),
        Divider(color: Colors.grey.withValues(alpha: 0.5)),
        const Gap(20),
        CustomText(
          text: 'Order Payment Details',
          size: 18,
          weight: FontWeight.w400,
        ),
        const Gap(20),
        Row(
          children: [
            CustomText(text: 'Order Amount', size: 16, weight: FontWeight.w400),
            const Spacer(),
            CustomText(
              text: '\u20B9${_price(subtotal)}',
              size: 15,
              weight: FontWeight.w500,
              color: AppColors.blackColor,
            ),
          ],
        ),
        const Gap(20),
        Row(
          children: [
            CustomText(text: 'Delivery Fee', size: 16, weight: FontWeight.w400),
            const Spacer(),
            CustomText(
              text: '\u20B9${_price(shippingFee)}',
              size: 14,
              weight: FontWeight.w500,
              color: AppColors.blackColor,
            ),
          ],
        ),
        if (discountAmount > 0) ...[
          const Gap(20),
          Row(
            children: [
              CustomText(text: 'Discount', size: 16, weight: FontWeight.w400),
              const Spacer(),
              CustomText(
                text: '- \u20B9${_price(discountAmount)}',
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.redColor,
              ),
            ],
          ),
        ],
        Divider(color: Colors.grey.withValues(alpha: 0.5)),
        const Gap(10),
        Row(
          children: [
            CustomText(text: 'Order Total', size: 18, weight: FontWeight.w400),
            const Spacer(),
            CustomText(
              text: '\u20B9${_price(total)}',
              size: 18,
              weight: FontWeight.w700,
              color: AppColors.blackColor,
            ),
          ],
        ),
      ],
    );
  }
}
