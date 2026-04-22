import 'package:flutter/material.dart';

const TextStyle creditCardTextStyle = TextStyle(
  color: Colors.black,
  fontFamily: 'halter',
  fontSize: 14,
  package: 'flutter_credit_card',
);

OutlineInputBorder blackBorder([double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: Colors.black, width: width),
  );
}

OutlineInputBorder redBorder() {
  return const OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: Colors.red, width: 1),
  );
}

InputDecoration creditCardDecoration({
  required String label,
  String? hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: Colors.black),
    floatingLabelStyle: const TextStyle(color: Colors.black),

    enabledBorder: blackBorder(),
    focusedBorder: blackBorder(1.5),
    errorBorder: redBorder(),
    focusedErrorBorder: redBorder(),

    suffixIcon: suffixIcon,
  );
}
