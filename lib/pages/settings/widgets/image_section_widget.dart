import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hungry/pages/auth/widgets/app_snackbar.dart';
import 'package:hungry/pages/settings/data/profile_service.dart';
import 'package:hungry/pages/settings/data/user_model.dart';
import 'package:hungry/pages/settings/widgets/image_section.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

class ImageSectionWidget extends StatefulWidget {
  const ImageSectionWidget({super.key});

  @override
  State<ImageSectionWidget> createState() => _ImageSectionWidgetState();
}

class _ImageSectionWidgetState extends State<ImageSectionWidget> {
  bool isloadingImage = false;
  final ProfileService _profileService = ProfileService();

  String? selctedimage;
  UserModel? _user;

  Future<void> pickeImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    try {
      setState(() => isloadingImage = true);

      final imageUrl = await _profileService.uploadProfileImage(
        File(picked.path),
      );

      _user ??= await _profileService.getProfile();

      if (!mounted || _user == null) return;

      await _profileService.updateProfileImage(
        userId: _user!.userId,
        imageUrl: imageUrl,
      );

      setState(() {
        selctedimage =
            '$imageUrl?v=${DateTime.now().microsecondsSinceEpoch}'; // ✅ URL مش path
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context: context,
        text: 'Failed to upload image',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => isloadingImage = false);
    }
  }

  Future<void> loadProfileImage() async {
    setState(() => isloadingImage = true);
    final profile = await _profileService.getProfile();
    if (!mounted) return;

    _user = profile;
    if (_user != null) {
      selctedimage = _user!.image;
    }
    setState(() => isloadingImage = false);
  }

  @override
  void initState() {
    super.initState();
    loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isloadingImage == true
          ? Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            )
          : ImageSection(
              onTapUploadImage: pickeImage,
              image: selctedimage != null ? NetworkImage(selctedimage!) : null,
            ),
    );
  }
}
