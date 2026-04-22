import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/product/widgets/product_app_bar.dart';
import 'package:hungry/pages/settings/data/payment_service.dart';
import 'package:hungry/pages/settings/data/pyment_model.dart';
import 'package:hungry/pages/settings/widgets/add_payment_btn.dart';
import 'package:hungry/pages/settings/widgets/credit_card_form_data.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

class AddPaymentCard extends StatefulWidget {
  const AddPaymentCard({super.key});

  @override
  State<StatefulWidget> createState() => AddPaymentCardState();
}

class AddPaymentCardState extends State<AddPaymentCard> {
  bool isLoading = false;
  bool isCardNumberObscured = true;

  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  bool useGlassMorphism = false;
  bool useBackgroundImage = false;
  bool useFloatingAnimation = true;
  late final cleanNumber = cardNumber.replaceAll(' ', '');
  final _paymentService = PaymentService();

  String cardBrand = '';
  // CardTypeType = CardType.otherBrand;
  final OutlineInputBorder border = OutlineInputBorder(
    borderSide: BorderSide(
      color: Colors.grey.withValues(alpha: 0.7),
      width: 2.0,
    ),
  );
  // final SupabaseClient _supabase = Supabase.instance.client;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  // void onCreditCardWidgetChange(CreditCardBrand brand) {
  //   setState(() {
  //     cardType = brand.brandName ?? CardType.otherBrand;
  //   });
  // }

  String getCardBrand(CardType type) {
    return type.toString().split('.').last;
  }

  AddPaymentMethodDto _buildPaymentMethod() {
    final parts = expiryDate.split('/');
    final cleanNumber = cardNumber.replaceAll(' ', '');

    return AddPaymentMethodDto(
      holderName: cardHolderName.trim(),
      last4: cleanNumber.substring(cleanNumber.length - 4),
      brand: cardBrand,
      expMonth: int.parse(parts[0]),
      expYear: int.parse('20${parts[1]}'),
    );
  }

  Future<void> submitPaymentCard() async {
    if (!formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);

      await _paymentService.addPaymentMethod(_buildPaymentMethod());

      if (!mounted) return;
      setState(() => isLoading = false);

      AppSnackBar.show(
        context: context,
        text: 'Card added successfully.',
        backgroundColor: Colors.green,
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: 'Failed to add card.',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        body: Builder(
          builder: (BuildContext context) {
            return Container(
              decoration: BoxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ProductAppBar(
                      text: 'Add Card',
                      padiing: 0,
                      showbackicon: true,
                    ),
                  ),

                  CreditCardWidget(
                    cardBgColor: Colors.black,
                    enableFloatingCard: useFloatingAnimation,
                    cardNumber: cardNumber,
                    expiryDate: expiryDate,
                    cardHolderName: cardHolderName.toUpperCase(),
                    cvvCode: cvvCode,

                    frontCardBorder: useGlassMorphism
                        ? null
                        : Border.all(color: Colors.grey),
                    backCardBorder: useGlassMorphism
                        ? null
                        : Border.all(color: Colors.grey),
                    showBackView: isCvvFocused,
                    obscureCardNumber: true,
                    obscureCardCvv: true,
                    isHolderNameVisible: true,

                    isSwipeGestureEnabled: true,
                    onCreditCardWidgetChange:
                        (CreditCardBrand creditCardBrand) {
                          cardBrand = getCardBrand(creditCardBrand.brandName!);
                        },
                    customCardTypeIcons: <CustomCardTypeIcon>[],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          CreditCardFormData(
                            formKey: formKey,
                            isCardNumberObscured: isCardNumberObscured,
                            cardNumber: cardNumber,
                            cvvCode: cvvCode,
                            cardHolderName: cardHolderName,
                            expiryDate: expiryDate,
                            onCreditCardModelChange: onCreditCardModelChange,
                            onPressedSuffixIcon: () {
                              setState(() {
                                isCardNumberObscured = !isCardNumberObscured;
                              });
                            },
                          ),

                          const SizedBox(height: 20),
                          isLoading
                              ? CupertinoActivityIndicator(
                                  color: AppColors.redColor,
                                  radius: 20,
                                )
                              : AddPaymentBtn(onValidate: submitPaymentCard),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void onCreditCardModelChange(CreditCardModel creditCardModel) {
    setState(() {
      cardNumber = creditCardModel.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }
}
