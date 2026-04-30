import 'package:flutter/material.dart';

enum PillVariant { success, warning, danger, info, neutral }

class MisePill extends StatelessWidget {
  final String label;
  final PillVariant variant;

  const MisePill({super.key, required this.label, this.variant = PillVariant.neutral});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      PillVariant.success => (const Color(0xFFEAF3DE), const Color(0xFF27500A)),
      PillVariant.warning => (const Color(0xFFFAEEDA), const Color(0xFF633806)),
      PillVariant.danger  => (const Color(0xFFFCEBEB), const Color(0xFF791F1F)),
      PillVariant.info    => (const Color(0xFFE6F1FB), const Color(0xFF0C447C)),
      PillVariant.neutral => (const Color(0xFFF1EFE8), const Color(0xFF5F5E5A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}