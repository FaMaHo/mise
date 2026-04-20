import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const heading2 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const heading3 = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const bodySecondary = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );
}