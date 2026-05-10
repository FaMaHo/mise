import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/mise_card.dart';
import '../../core/widgets/mise_pill.dart';
import '../../core/widgets/scan_bottom_sheet.dart';
import '../../core/widgets/add_item_bottom_sheet.dart';
import '../../core/di/household_id_provider.dart';
import 'bloc/pantry_bloc.dart';
import 'bloc/pantry_event.dart';
import 'bloc/pantry_state.dart';

Future<void> openAddPantrySheet(BuildContext context) async {
  final householdId = HouseholdIdProvider.of(context);

  if (householdId == null) return;

  final result = await showAddItemBottomSheet(context);

  if (result == null) return;

  context.read<PantryBloc>().add(
    PantryItemAdded(
      householdId: householdId,
      name: result.name,
      quantity: result.quantity,
      expiryDate: result.expiry,
    ),
  );
}

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  void _addItem(String name, {int quantity = 1, DateTime? expiryDate}) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) return;

    final householdId = HouseholdIdProvider.of(context);

    if (householdId == null) return;

    context.read<PantryBloc>().add(
      PantryItemAdded(
        householdId: householdId,
        name: trimmed,
        quantity: quantity,
        expiryDate: expiryDate,
      ),
    );
  }

  Future<void> _openScanner() async {
    final scannedName = await showScanBottomSheet(
      context,
      scanContext: ScanContext.pantry,
    );

    if (scannedName != null && mounted) {
      final result = await showAddItemBottomSheet(
        context,
        prefillName: scannedName,
      );

      if (result != null) {
        _addItem(
          result.name,
          quantity: result.quantity,
          expiryDate: result.expiry,
        );
      }
    }
  }

  Future<void> _openManualAdd() async {
    final result = await showAddItemBottomSheet(context);

    if (result != null) {
      _addItem(
        result.name,
        quantity: result.quantity,
        expiryDate: result.expiry,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Pantry', style: AppTextStyles.screenTitle),
                  ),

                  // Manual Add
                  GestureDetector(
                    onTap: _openManualAdd,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Scanner
                  GestureDetector(
                    onTap: _openScanner,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<PantryBloc, PantryState>(
                builder: (context, state) {
                  if (state is PantryLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  if (state is PantryLoaded) {
                    if (state.items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.kitchen_outlined,
                              size: 48,
                              color: AppColors.borderStrong,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your pantry is empty',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + or scan to add items',
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Text(
                          '${state.items.length} items',
                          style: AppTextStyles.label,
                        ),

                        const SizedBox(height: 8),

                        MiseCard(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            children: List.generate(
                              state.items.length * 2 - 1,
                              (i) {
                                if (i.isOdd) {
                                  return const _RowDivider();
                                }

                                final item = state.items[i ~/ 2];

                                int? daysLeft;

                                if (item.expiryDate != null) {
                                  daysLeft = item.expiryDate!
                                      .difference(DateTime.now())
                                      .inDays;
                                }

                                return Dismissible(
                                  key: ValueKey(item.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: AppColors.dangerBackground,
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.dangerText,
                                    ),
                                  ),
                                  onDismissed: (_) {
                                    context.read<PantryBloc>().add(
                                      PantryItemRemoved(
                                        item.id,
                                        item.householdId,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: AppTextStyles.body,
                                              ),
                                              if (item.quantity > 1)
                                                Text(
                                                  '×${item.quantity}',
                                                  style: AppTextStyles.caption,
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (daysLeft != null)
                                          MisePill(
                                            label: daysLeft == 0
                                                ? 'Today'
                                                : daysLeft == 1
                                                ? 'Tomorrow'
                                                : '$daysLeft days',
                                            variant: daysLeft <= 0
                                                ? PillVariant.danger
                                                : PillVariant.warning,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Swipe left to remove from pantry',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
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
