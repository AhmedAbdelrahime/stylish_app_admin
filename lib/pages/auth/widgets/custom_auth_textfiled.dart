import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';

class CustomAuthTextfiled extends StatefulWidget {
  const CustomAuthTextfiled({
    super.key,
    required this.controller,
    required this.labelText,
    this.isPassowed = false,
    this.keyboardType,
    required this.icone,
    this.validator,
  });
  final TextEditingController controller;
  final String labelText;
  final bool isPassowed;
  final TextInputType? keyboardType;
  final IconData icone;
  final String? Function(String?)? validator;

  @override
  State<CustomAuthTextfiled> createState() => _CustomAuthTextfiledState();
}

class _CustomAuthTextfiledState extends State<CustomAuthTextfiled> {
  late bool _obsecureText;
  @override
  void initState() {
    _obsecureText = widget.isPassowed;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      controller: widget.controller,
      obscureText: _obsecureText,
      cursorColor: AppColors.grayColor,
      decoration: InputDecoration(
        suffixIcon: widget.isPassowed
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obsecureText = !_obsecureText;
                  });
                },
                icon: Icon(
                  _obsecureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.hintColor,
                ),
              )
            : null,
        prefixIcon: Icon(widget.icone),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grayColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grayColor, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.redColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.redColor, width: 1),
        ),
        hintText: widget.labelText,
        hintStyle: TextStyle(color: AppColors.hintColor, fontSize: 14),
        filled: true,
        fillColor: AppColors.grayColor.withValues(alpha: .2),
      ),
    );
  }
}
