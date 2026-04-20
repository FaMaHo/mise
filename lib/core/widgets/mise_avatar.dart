import 'package:flutter/material.dart';

class MiseAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? background;
  final Color? foreground;

  const MiseAvatar({
    super.key,
    required this.initials,
    this.size = 32,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: background ?? const Color(0xFFE6F1FB),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w500,
          color: foreground ?? const Color(0xFF0C447C),
        ),
      ),
    );
  }
}