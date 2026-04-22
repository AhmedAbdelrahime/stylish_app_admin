import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/settings/data/pyment_model.dart';
import 'package:hungry/shared/custom_text.dart';

class PymentsDetails extends StatefulWidget {
  const PymentsDetails({
    super.key,
    this.chekeout = false,
    this.ontap,
    this.pymentMethod,
    this.onDelete,
  });

  final bool? chekeout;
  final VoidCallback? ontap;
  final List<PaymentMethod>? pymentMethod;
  final Function(int)? onDelete;

  @override
  State<PymentsDetails> createState() => _PymentsDetailsState();
}

class _PymentsDetailsState extends State<PymentsDetails> {
  int? selectedIndex;
  // no selection initially

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.pymentMethod?.length ?? 0, (index) {
        final isSelected = selectedIndex == index;

        return GestureDetector(
          onTap: widget.ontap,
          child: GestureDetector(
            onTap: () {
              widget.chekeout == true
                  ? setState(() {
                      selectedIndex = index;
                    })
                  : null;
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1.5,
                  color: isSelected ? AppColors.redColor : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.grayColor.withValues(alpha: .3),
              ),
              child: Row(
                children: [
                  Image.asset(
                    "assets/images/paymenticons/${widget.pymentMethod![index].brand}.png",
                    height: 30,
                  ),
                  const Spacer(),
                  CustomText(
                    text: "**** **** **** ${widget.pymentMethod![index].last4}",
                    size: 16,
                    weight: FontWeight.w500,
                    color: AppColors.hintColor,
                  ),
                  Gap(10),
                  widget.chekeout == true
                      ? const SizedBox.shrink()
                      : GestureDetector(
                          onTap: () {
                            // Call onDelete callback with the current index
                            widget.onDelete?.call(index);
                          },
                          child: CustomText(
                            text: "Delete",
                            size: 14,
                            weight: FontWeight.w500,
                            color: Colors.pinkAccent,
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
