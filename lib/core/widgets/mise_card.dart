import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MiseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const MiseCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: child,
      ),
    );
  }
}