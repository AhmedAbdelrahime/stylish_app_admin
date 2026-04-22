import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';

class SearchTextField extends StatelessWidget {
  const SearchTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.hintText = 'Search for products, brands, and styles',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTap: onTap,
          cursorColor: AppColors.blackColor,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            prefixIcon: const Icon(Icons.search, color: AppColors.grayColor),
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.grayColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
