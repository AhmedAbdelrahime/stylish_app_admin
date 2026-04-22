import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SmartRefreshWidget extends StatelessWidget {
  const SmartRefreshWidget({super.key, required this.controller, this.onRefresh, required this.child});
 final  RefreshController controller;
 final void Function()? onRefresh;
 final Widget child;

  @override
  Widget build(BuildContext context) {
    return  SmartRefresher(
                  controller: controller,
                  enablePullDown: true,
                  enablePullUp: false,
                  header: WaterDropHeader(
                    waterDropColor: AppColors.redColor,
                    complete: const Icon(
                      Icons.check,
                      color: Colors.greenAccent,
                    ),
                    completeDuration: Duration(milliseconds: 500),

                    refresh: CupertinoActivityIndicator(
                      color: Colors.white,
                      radius: 20,
                    ),
                  ),

                  onRefresh: onRefresh,
                  child: child);
  }
}