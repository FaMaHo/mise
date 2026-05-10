import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/mise_card.dart';
import '../../core/widgets/mise_pill.dart';
import '../../core/widgets/scan_bottom_sheet.dart';
import '../../core/di/household_id_provider.dart';
import 'bloc/pantry_bloc.dart';
import 'bloc/pantry_event.dart';
import 'bloc/pantry_state.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _controller = TextEditingController();

  void _addItem(String name, {int quantity = 1, DateTime? expiryDate}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final householdId = HouseholdIdProvider.of(context);
    if (householdId == null) return;
    context.read<PantryBloc>().add(PantryItemAdded(
          householdId: householdId,
          name: trimmed,
          quantity: quantity,
          expiryDate: expiryDate,
        ));
    _controller.clear();
  }

  Future<void> _openScanner() async {
    final scannedName = await showScanBottomSheet(
      context,
      scanContext: ScanContext.pantry,
    );
    if (scannedName != null && mounted) {
      // Show confirmation sheet with editable fields
      final result = await _showAddConfirmSheet(scannedName);
      if (result != null) {
        _addItem(result.name, quantity: result.quantity, expiryDate: result.expiry);
      }
    }
  }

  Future<void> _openManualAdd() async {
    final result = await _showAddConfirmSheet('');
    if (result != null) {
      _addItem(result.name, quantity: result.quantity, expiryDate: result.expiry);
    }
  }

  Future<_AddResult?> _showAddConfirmSheet(String prefillName) {
    return showModalBottomSheet<_AddResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(prefillName: prefillName),
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Pantry', style: AppTextStyles.screenTitle),
                  ),
                  // Manual add button
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
                      child: const Icon(Icons.add_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Scan button
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
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: BlocBuilder<PantryBloc, PantryState>(
                builder: (context, state) {
                  if (state is PantryLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    );
                  }
                  if (state is PantryLoaded) {
                    if (state.items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.kitchen_outlined,
                                size: 48, color: AppColors.borderStrong),
                            const SizedBox(height: 12),
                            Text('Your pantry is empty',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              'Check off items on your shopping list\nor tap + to add directly',
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
                        Text('${state.items.length} items',
                            style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        MiseCard(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            children: List.generate(
                              state.items.length * 2 - 1,
                              (i) {
                                if (i.isOdd) return const _RowDivider();
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
                                        size: 20),
                                  ),
                                  onDismissed: (_) {
                                    final householdId =
                                        HouseholdIdProvider.of(context);
                                    context.read<PantryBloc>().add(
                                        PantryItemRemoved(
                                            item.id, item.householdId));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(item.name,
                                                  style: AppTextStyles.body),
                                              if (item.quantity > 1)
                                                Text('×${item.quantity}',
                                                    style:
                                                        AppTextStyles.caption),
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

// ── Add/Confirm bottom sheet ──────────────────────────────────────────────────

class _AddResult {
  final String name;
  final int quantity;
  final DateTime? expiry;
  const _AddResult({required this.name, required this.quantity, this.expiry});
}

class _AddItemSheet extends StatefulWidget {
  final String prefillName;
  const _AddItemSheet({required this.prefillName});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  late final TextEditingController _nameController;
  int _quantity = 1;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefillName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.background,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      _AddResult(name: name, quantity: _quantity, expiry: _expiryDate),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.prefillName.isEmpty;
    return Padding(
      // Shift up when keyboard appears
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEdit ? 'Add to pantry' : 'Confirm item',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 20),

            // Name field
            TextField(
              controller: _nameController,
              autofocus: isEdit,
              textCapitalization: TextCapitalization.sentences,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                labelText: 'Item name',
                labelStyle:
                    AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quantity row
            Row(
              children: [
                Text('Quantity', style: AppTextStyles.body),
                const Spacer(),
                _QuantityStepper(
                  value: _quantity,
                  onChanged: (v) => setState(() => _quantity = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Expiry row
            GestureDetector(
              onTap: _pickExpiry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      _expiryDate != null
                          ? 'Expires ${_formatDate(_expiryDate!)}'
                          : 'Add expiry date (optional)',
                      style: AppTextStyles.body.copyWith(
                        color: _expiryDate != null
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    if (_expiryDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _expiryDate = null),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Add button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _submit,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Add to pantry',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.background,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quantity stepper ──────────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(
          icon: Icons.remove_rounded,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$value', style: AppTextStyles.heading3),
        ),
        _StepBtn(
          icon: Icons.add_rounded,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null
                ? AppColors.borderStrong
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? AppColors.textPrimary
              : AppColors.textTertiary,
        ),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 0.5,
        indent: 14,
        endIndent: 14,
        color: AppColors.border,
      );
}