import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/settings/data/payment_service.dart';
import 'package:hungry/pages/settings/data/pyment_model.dart';
import 'package:hungry/pages/settings/widgets/addcard.dart';
import 'package:hungry/pages/settings/widgets/logout_dialog.dart';
import 'package:hungry/pages/settings/widgets/payment_details.dart';
import 'package:hungry/shared/custom_text.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PaymentSection extends StatefulWidget {
  const PaymentSection({super.key});

  @override
  State<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<PaymentSection> {
  final PaymentService _paymentService = PaymentService();
  List<PaymentMethod> _methods = [];

  bool isloading = false;
  bool isDelete = false;

  Future<void> loadPaymentMethods() async {
    setState(() => isloading = true);

    final methods = await _paymentService.getPaymentMethods();
    if (!mounted) return;

    setState(() {
      _methods = methods;
      isloading = false;
    });
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      setState(() => isDelete = true);

      await _paymentService.deletePaymentMethod(paymentMethodId);
      if (!mounted) return;

      // remove locally (faster UX)
      _methods.removeWhere((m) => m.id == paymentMethodId);

      setState(() => isDelete = false);

      AppSnackBar.show(
        context: context,
        text: 'Card deleted successfully',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isDelete = false);

      AppSnackBar.show(
        context: context,
        text: 'Failed to delete card',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> showDeletePaymentDialog(String paymentMethodId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LogoutDialog(isDeleteCard: true),
    );

    if (shouldDelete == true) {
      await deletePaymentMethod(paymentMethodId);
    }
  }

  @override
  void initState() {
    super.initState();
    loadPaymentMethods();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Gap(20),

        CustomText(
          text: 'Bank Account Details',
          size: 18,
          weight: FontWeight.w600,
        ),
        Skeletonizer(
          enabled: isloading,
          child: PymentsDetails(
            chekeout: false,
            pymentMethod: _methods,
            onDelete: (index) {
              final method = _methods[index];

              if (method.id == null) return;

              showDeletePaymentDialog(method.id!);
            },
          ),
        ),
        Gap(10),
        AddCardButton(onCardAdded: loadPaymentMethods),

        Gap(100),
      ],
    );
  }
}
