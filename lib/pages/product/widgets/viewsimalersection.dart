import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';

class ViewSimalerSection extends StatelessWidget {
  const ViewSimalerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Similar To This',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.blackColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Related picks based on the current product category.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.hintColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
