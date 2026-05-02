import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum PillVariant { success, warning, danger, info, neutral }

class MisePill extends StatelessWidget {
  final String label;
  final PillVariant variant;

  const MisePill({
    super.key,
    required this.label,
    this.variant = PillVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      PillVariant.success => (AppColors.successBg, AppColors.successText),
      PillVariant.warning => (AppColors.warningBg, AppColors.warningText),
      PillVariant.danger => (AppColors.dangerBg, AppColors.dangerText),
      PillVariant.info => (AppColors.infoBg, AppColors.infoText),
      PillVariant.neutral => (
        AppColors.surfaceSecondary,
        AppColors.textSecondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
