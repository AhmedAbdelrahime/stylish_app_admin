import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hungry/pages/settings/widgets/change_password_sheet_widget.dart';
import 'package:hungry/pages/settings/widgets/text_field_custom.dart';
import 'package:hungry/shared/custom_text.dart';

class SettingForm extends StatelessWidget {
  const SettingForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.pinCodeontroller,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.countryController,
  });
  final TextEditingController nameController;
  final TextEditingController pinCodeontroller;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController countryController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Gap(25),
        CustomText(text: 'Personal Details', size: 18, weight: FontWeight.w600),
        SettingTextField(controller: nameController, labelText: 'UserName'),
        SettingTextField(
          controller: emailController,
          labelText: 'Email',
          enabled: false,
        ),
        Gap(10),
        ChangePasswordSheetWidget(),
        Gap(10),

        Divider(),
        CustomText(
          text: 'Business Address Details',
          size: 18,
          weight: FontWeight.w600,
        ),

        SettingTextField(controller: pinCodeontroller, labelText: 'Pincode'),
        SettingTextField(controller: addressController, labelText: ' Address'),
        SettingTextField(controller: cityController, labelText: ' City'),
        SettingTextField(controller: stateController, labelText: ' State'),
        SettingTextField(controller: countryController, labelText: 'Country'),
        Divider(),
      ],
    );
  }
}
