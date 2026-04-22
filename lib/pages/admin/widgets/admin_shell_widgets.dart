import 'package:flutter/material.dart';
import 'package:hungry/core/constants/app_colors.dart';

class AdminSurfaceCard extends StatelessWidget {
  const AdminSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.backgroundColor = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 18),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminSectionIntro extends StatelessWidget {
  const AdminSectionIntro({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blackColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.hintColor,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 16), trailing!],
      ],
    );
  }
}

class AdminTag extends StatelessWidget {
  const AdminTag({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.isCompact = false,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor ?? AppColors.blackColor,
          fontSize: isCompact ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AdminEmptyPanel extends StatelessWidget {
  const AdminEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.redColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.blackColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminResponsiveSplit extends StatelessWidget {
  const AdminResponsiveSplit({
    super.key,
    required this.primary,
    required this.secondary,
    this.breakpoint = 1080,
    this.spacing = 20,
    this.primaryFlex = 5,
    this.secondaryFlex = 4,
  });

  final Widget primary;
  final Widget secondary;
  final double breakpoint;
  final double spacing;
  final int primaryFlex;
  final int secondaryFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              primary,
              SizedBox(height: spacing),
              secondary,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: primaryFlex, child: primary),
            SizedBox(width: spacing),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}
