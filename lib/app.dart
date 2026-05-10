import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/shopping/shopping_screen.dart';
import 'features/pantry/pantry_screen.dart';
import 'features/cook/cook_screen.dart';
import 'features/auth/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/di/service_locator.dart';
import 'features/pantry/bloc/pantry_bloc.dart';
import 'features/pantry/bloc/pantry_event.dart';
import 'features/shopping/bloc/shopping_bloc.dart';
import 'features/shopping/bloc/shopping_event.dart';
import 'core/di/household_id_provider.dart';

class MiseApp extends StatelessWidget {
  const MiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mise',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
            );
          }
          if (snapshot.hasData) return const MainShell();
          return const AuthScreen();
        },
      ),
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
  String? _householdId;

  @override
  void initState() {
    super.initState();
    _loadHouseholdId();
  }

  Future<void> _loadHouseholdId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted) {
      setState(() => _householdId = doc.data()?['householdId']);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_householdId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return HouseholdIdProvider(
      householdId: _householdId!,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => PantryBloc(sl.pantryRepository)
              ..add(PantryStarted(_householdId!)),
          ),
          BlocProvider(
            create: (_) => ShoppingBloc(sl.shoppingRepository, sl.pantryRepository)
              ..add(ShoppingStarted(_householdId!)),
          ),
        ],
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              HomeScreen(),
              ShoppingScreen(),
              PantryScreen(),
              CookScreen(),
            ],
          ),
          bottomNavigationBar: _MiseNavBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        ),
      ),
    );
  }
}

class _MiseNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MiseNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: 'Shopping'),
    (icon: Icons.kitchen_outlined, activeIcon: Icons.kitchen_rounded, label: 'Pantry'),
    (icon: Icons.restaurant_outlined, activeIcon: Icons.restaurant_rounded, label: 'Cook'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 24, left: 12, right: 12),
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
                  horizontal: active ? 16 : 10, vertical: 8),
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