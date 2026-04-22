import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/settings/data/profile_service.dart';
import 'package:hungry/pages/settings/data/user_model.dart';
import 'package:hungry/pages/settings/widgets/app_bar_section.dart';
import 'package:hungry/pages/settings/widgets/custom_bottom_sheet.dart';
import 'package:hungry/pages/settings/widgets/image_section_widget.dart';
import 'package:hungry/pages/settings/widgets/payment_section.dart';
import 'package:hungry/pages/settings/widgets/setting_form.dart';
import 'package:hungry/pages/settings/widgets/smart_refresh_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pinCodeontroller = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final RefreshController _refreshcontroller = RefreshController(
    initialRefresh: false,
  );
  final ProfileService _profileService = ProfileService();
  bool isloading = false;
  bool isloadingData = false;
  bool isDelete = false;
  UserModel? _user;
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    pinCodeontroller.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    setState(() => isloadingData = true);
    final profile = await _profileService.getProfile();
    if (!mounted) return;

    _user = profile;
    if (_user != null) {
      nameController.text = _user!.name ?? '';
      emailController.text = _user!.email;
      addressController.text = _user!.address ?? '';
      cityController.text = _user!.city ?? '';
      stateController.text = _user!.state ?? '';
      countryController.text = _user!.country ?? '';
      pinCodeontroller.text = _user!.pincode ?? '';
    }
    setState(() => isloadingData = false);
  }

  Future<void> updateProfile() async {
    if (_user == null) return;
    setState(() => isloading = true);
    final updatedUser = UserModel(
      userId: _user!.userId,
      email: _user!.email,
      name: nameController.text,
      address: addressController.text,
      city: cityController.text,
      state: stateController.text,
      country: countryController.text,
      pincode: pinCodeontroller.text,
      image: _user!.image,
    );
    await _profileService.updateProfile(updatedUser);
    if (!mounted) return;
    _user = updatedUser;
    setState(() => isloading = false);
    AppSnackBar.show(
      context: context,
      text: 'Profile updated successfully.',
      backgroundColor: Colors.green,
    );
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        appBar: AppBarSection(),
        backgroundColor: AppColors.primaryColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SmartRefreshWidget(
                  controller: _refreshcontroller,
                  onRefresh: () async {
                    await loadUserData();
                    _refreshcontroller.refreshCompleted();
                  },
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Skeletonizer(
                      enabled: isloadingData,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ImageSectionWidget(),
                          const SizedBox(height: 16),

                          SettingForm(
                            nameController: nameController,
                            emailController: emailController,
                            pinCodeontroller: pinCodeontroller,
                            addressController: addressController,
                            cityController: cityController,
                            stateController: stateController,
                            countryController: countryController,
                          ),
                          PaymentSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomSheet: CustomBottomsheet(
          isloadingUpdate: isloading,
          upadateProfileData: updateProfile,
        ),
      ),
    );
  }
}
