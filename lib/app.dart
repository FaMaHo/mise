import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/cook/cook_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/auth/auth_screen.dart';

class MiseApp extends StatelessWidget {
  const MiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mise',
      theme: AppTheme.light,
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    ScanScreen(),
    CookScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _MiseNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _MiseNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MiseNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    (
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Pantry',
    ),
    (
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant_rounded,
      label: 'Cook',
    ),
    (
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      label: 'Household',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 24,
        left: 12,
        right: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final active = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: active ? 16 : 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? item.activeIcon : item.icon,
                    size: 18,
                    color: active
                        ? AppColors.background
                        : AppColors.textTertiary,
                  ),
                  if (active) ...[
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.background,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}