import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/mise_card.dart';
import '../../core/widgets/mise_pill.dart';
import '../../core/widgets/mise_avatar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../pantry/bloc/pantry_bloc.dart';
import '../pantry/bloc/pantry_state.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: const [
            _Header(),
            SizedBox(height: 28),
            _ShoppingNowSection(),
            SizedBox(height: 28),
            _ExpiringSection(),
            SizedBox(height: 28),
            _ShoppingListSection(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(), style: AppTextStyles.greeting),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Flat 4B', style: AppTextStyles.caption),
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.borderStrong,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('3 members', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            _IconButton(
              icon: Icons.notifications_outlined,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _IconButton(
              icon: Icons.add,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.surfaceSecondary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Shopping now ──────────────────────────────────────────────────────────────

class _ShoppingNowSection extends StatelessWidget {
  const _ShoppingNowSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Shopping now'),
        const SizedBox(height: 8),
        MiseCard(
          child: Row(
            children: [
              const _LiveDot(),
              const SizedBox(width: 12),
              const MiseAvatar(
                initials: 'AN',
                background: AppColors.primaryLight,
                foreground: AppColors.primaryText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ana is shopping', style: AppTextStyles.heading3),
                    const SizedBox(height: 2),
                    Text('12 min ago', style: AppTextStyles.caption),
                  ],
                ),
              ),
              _ShoppingButton(onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShoppingButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShoppingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "I'm shopping",
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.background,
          ),
        ),
      ),
    );
  }
}

// ── Expiring soon ─────────────────────────────────────────────────────────────

class _ExpiringSection extends StatelessWidget {
  const _ExpiringSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PantryBloc, PantryState>(
      builder: (context, state) {
        if (state is! PantryLoaded || state.expiringItems.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = state.expiringItems;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel('Expiring soon'),
                Text('${items.length} items', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            MiseCard(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: List.generate(items.length * 2 - 1, (i) {
                  if (i.isOdd) return const _RowDivider();
                  final item = items[i ~/ 2];
                  final daysLeft = item.expiryDate!
                      .difference(DateTime.now())
                      .inDays;
                  final label = daysLeft == 0
                      ? 'Today'
                      : daysLeft == 1
                          ? 'Tomorrow'
                          : '$daysLeft days';
                  final variant = daysLeft == 0
                      ? PillVariant.danger
                      : PillVariant.warning;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(item.name, style: AppTextStyles.body),
                        ),
                        MisePill(label: label, variant: variant),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }
}

// ── Shopping list ─────────────────────────────────────────────────────────────

class _ShoppingListItem {
  final String name;
  final String quantity;
  final bool checked;
  const _ShoppingListItem(this.name, this.quantity, {this.checked = false});
}

class _ShoppingListSection extends StatelessWidget {
  const _ShoppingListSection();

  static const _items = [
    _ShoppingListItem('Eggs',      '×2'),
    _ShoppingListItem('Butter',    '×1'),
    _ShoppingListItem('Olive oil', '×1'),
    _ShoppingListItem('Pasta',     '×1', checked: true),
  ];

  static int get _uncheckedCount => _items.where((i) => !i.checked).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('Shopping list'),
            MisePill(
              label: '$_uncheckedCount left',
              variant: PillVariant.success,
            ),
          ],
        ),
        const SizedBox(height: 8),
        MiseCard(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: List.generate(_items.length * 2 - 1, (i) {
              if (i.isOdd) return const _RowDivider();
              final item = _items[i ~/ 2];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _Checkbox(checked: item.checked),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: item.checked
                            ? AppTextStyles.body.copyWith(
                                color: AppColors.textDisabled,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.textDisabled,
                              )
                            : AppTextStyles.body,
                      ),
                    ),
                    Text(item.quantity, style: AppTextStyles.caption),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTextStyles.label);
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      indent: 14,
      endIndent: 14,
      color: AppColors.border,
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  const _Checkbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: checked ? AppColors.primary : AppColors.borderStrong,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 13, color: AppColors.background)
          : null,
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scale = Tween<double>(begin: 1.0, end: 2.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.live,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.live,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning,\nFatemeh!';
  if (hour < 17) return 'Good afternoon,\nFatemeh!';
  return 'Good evening,\nFatemeh!';
}