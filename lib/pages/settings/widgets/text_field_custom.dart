import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/shared/custom_text.dart';

class SettingTextField extends StatefulWidget {
  const SettingTextField({
    super.key,
    required this.controller,
    this.keyboardType,
    required this.labelText,
    this.isPassowed = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String labelText;
  final bool isPassowed;
  final bool enabled;

  @override
  State<SettingTextField> createState() => _SettingTextFieldState();
}

class _SettingTextFieldState extends State<SettingTextField> {
  late bool _obsecureText;

  @override
  void initState() {
    super.initState();
    _obsecureText = widget.isPassowed;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(5),
        CustomText(
          text: widget.labelText,
          size: 15,
          weight: FontWeight.w400,
          color: isEnabled ? AppColors.blackColor : AppColors.grayColor,
        ),
        const Gap(10),

        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _obsecureText,
          enabled: isEnabled,
          readOnly: !isEnabled,
          cursorColor: isEnabled ? AppColors.blackColor : Colors.transparent,
          style: TextStyle(
            color: isEnabled ? AppColors.blackColor : AppColors.grayColor,
            fontWeight: FontWeight.w500,
          ),

          decoration: InputDecoration(
            filled: true,
            fillColor: isEnabled
                ? AppColors.primaryColor
                : AppColors.grayColor.withValues(alpha: 0.15),

            // 👁 Password icon
            suffixIcon: widget.isPassowed
                ? IconButton(
                    onPressed: isEnabled
                        ? () {
                            setState(() {
                              _obsecureText = !_obsecureText;
                            });
                          }
                        : null,
                    icon: Icon(
                      _obsecureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: isEnabled
                          ? Colors.grey
                          : Colors.grey.withValues(alpha: 0.5),
                    ),
                  )
                : null,

            border: _border(isEnabled),
            enabledBorder: _border(isEnabled),
            focusedBorder: _border(isEnabled),
            disabledBorder: _border(false),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(bool enabled) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        width: 1.5,
        color: enabled
            ? AppColors.grayColor
            : AppColors.grayColor.withValues(alpha: 0.4),
      ),
    );
  }
}
