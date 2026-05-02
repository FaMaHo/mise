import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MiseTextField extends StatefulWidget {
  final String label;
  final String placeholder;
  final bool obscure;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? errorText;

  const MiseTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
  });

  @override
  State<MiseTextField> createState() => _MiseTextFieldState();
}

class _MiseTextFieldState extends State<MiseTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label.toUpperCase(), style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: widget.obscure && _obscured,
          keyboardType: widget.keyboardType,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textDisabled,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.dangerText,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            suffixIcon: widget.obscure
                ? GestureDetector(
                    onTap: () => setState(() => _obscured = !_obscured),
                    child: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  )
                : null,
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 5),
          Text(
            widget.errorText!,
            style: AppTextStyles.caption.copyWith(color: AppColors.dangerText),
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }
}
