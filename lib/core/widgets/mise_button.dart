import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ButtonVariant { primary, secondary }

class MiseButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final ButtonVariant variant;
  final bool loading;

  const MiseButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = ButtonVariant.primary,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == ButtonVariant.primary;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.borderStrong, width: 1),
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isPrimary ? AppColors.background : AppColors.primary,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? AppColors.background : AppColors.primary,
                  ),
                ),
        ),
      ),
    );
  }
}
