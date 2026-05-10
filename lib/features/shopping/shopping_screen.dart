import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/mise_card.dart';
import '../../core/widgets/scan_bottom_sheet.dart';
import 'bloc/shopping_bloc.dart';
import 'bloc/shopping_event.dart';
import 'bloc/shopping_state.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _controller = TextEditingController();

  void _addItem(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    context.read<ShoppingBloc>().add(ShoppingItemAdded(trimmed));
    _controller.clear();
  }

  Future<void> _openScanner() async {
    final name = await showScanBottomSheet(
      context,
      scanContext: ScanContext.shopping,
    );
    if (name != null && mounted) {
      _addItem(name);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Shopping list',
                        style: AppTextStyles.screenTitle),
                  ),
                  GestureDetector(
                    onTap: _openScanner,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Add item input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AppTextStyles.body,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Add an item...',
                        hintStyle: AppTextStyles.body.copyWith(
                            color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.border, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.border, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1),
                        ),
                      ),
                      onSubmitted: _addItem,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _addItem(_controller.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.background, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // List
            Expanded(
              child: BlocBuilder<ShoppingBloc, ShoppingState>(
                builder: (context, state) {
                  if (state is ShoppingLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    );
                  }
                  if (state is ShoppingLoaded) {
                    if (state.items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_basket_outlined,
                                size: 48, color: AppColors.borderStrong),
                            const SizedBox(height: 12),
                            Text('Nothing on the list yet',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }

                    final unchecked =
                        state.items.where((i) => !i.isChecked).toList();
                    final checked =
                        state.items.where((i) => i.isChecked).toList();
                    final displayed = [...unchecked, ...checked];

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        MiseCard(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            children: List.generate(
                              displayed.length * 2 - 1,
                              (i) {
                                if (i.isOdd) return const _RowDivider();
                                final item = displayed[i ~/ 2];
                                return _ShoppingRow(
                                  key: ValueKey(item.id),
                                  item: item,
                                  onCheckOff: () => context
                                      .read<ShoppingBloc>()
                                      .add(ShoppingItemCheckedOff(item.id)),
                                  onDelete: () => context
                                      .read<ShoppingBloc>()
                                      .add(ShoppingItemDeleted(item.id)),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Swipe left to delete · tap to move to pantry',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textTertiary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingRow extends StatelessWidget {
  final dynamic item;
  final VoidCallback onCheckOff;
  final VoidCallback onDelete;

  const _ShoppingRow({
    super.key,
    required this.item,
    required this.onCheckOff,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.dangerBackground,
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.dangerText, size: 20),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: item.isChecked ? null : onCheckOff,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _Checkbox(
                checked: item.isChecked,
                onTap: item.isChecked ? null : onCheckOff,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: item.isChecked
                      ? AppTextStyles.body.copyWith(
                          color: AppColors.textDisabled,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.textDisabled,
                        )
                      : AppTextStyles.body,
                ),
              ),
              Text('×${item.quantity}', style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  final VoidCallback? onTap;
  const _Checkbox({required this.checked, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
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
      ),
    );
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