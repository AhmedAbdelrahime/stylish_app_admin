import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';

class ImageSection extends StatelessWidget {
  const ImageSection({super.key, this.onTapUploadImage, required this.image});
  final VoidCallback? onTapUploadImage;
  final ImageProvider? image; // 👈 nullable

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        children: [
          ClipOval(
            child: Image(
              image: image ?? AssetImage('assets/images/profile.png'),
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            ),
          ),
          GestureDetector(
            onTap: onTapUploadImage,
            child: Align(
              alignment: AlignmentGeometry.bottomRight,
              child: Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryColor, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// 