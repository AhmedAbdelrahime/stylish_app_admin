import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';

import 'credit_card_input_styles.dart';

class CreditCardFormData extends StatelessWidget {
  const CreditCardFormData({
    super.key,
    required this.formKey,
    required this.isCardNumberObscured,
    required this.cardNumber,
    required this.cvvCode,
    required this.cardHolderName,
    required this.expiryDate,
    required this.onCreditCardModelChange,
    required this.onPressedSuffixIcon,
  });
  final GlobalKey<FormState> formKey;
  final bool isCardNumberObscured;
  final String cardNumber;
  final String cvvCode;
  final String cardHolderName;
  final String expiryDate;
  final void Function(CreditCardModel) onCreditCardModelChange;
  final void Function() onPressedSuffixIcon;

  @override
  Widget build(BuildContext context) {
    return CreditCardForm(
      formKey: formKey,
      obscureCvv: true,
      obscureNumber: isCardNumberObscured, // 👈 toggle
      cardNumber: cardNumber,
      cvvCode: cvvCode,
      isHolderNameVisible: true,
      isCardNumberVisible: true,
      isExpiryDateVisible: true,
      cardHolderName: cardHolderName,
      expiryDate: expiryDate,
      inputConfiguration: InputConfiguration(
        cardNumberTextStyle: creditCardTextStyle,
        cvvCodeTextStyle: creditCardTextStyle,
        expiryDateTextStyle: creditCardTextStyle,
        cardHolderTextStyle: creditCardTextStyle,

        cardNumberDecoration: creditCardDecoration(
          label: 'Number',
          hint: 'XXXX XXXX XXXX XXXX',
          suffixIcon: IconButton(
            icon: Icon(
              isCardNumberObscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: onPressedSuffixIcon,
          ),
        ),

        expiryDateDecoration: creditCardDecoration(
          label: 'Expired Date',
          hint: 'XX/XX',
        ),

        cvvCodeDecoration: creditCardDecoration(label: 'CVV', hint: 'XXX'),

        cardHolderDecoration: creditCardDecoration(label: 'CARD HOLDER NAME'),
      ),

      onCreditCardModelChange: onCreditCardModelChange,
    );
  }
}

//  () {
//                                     setState(() {
//                                       isCardNumberObscured =
//                                           !isCardNumberObscured;
//                                     });
//                                   },
