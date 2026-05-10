import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/mise_button.dart';
import '../../core/widgets/mise_card.dart';
import '../../core/widgets/mise_text_field.dart';
import '../pantry/bloc/pantry_bloc.dart';
import '../pantry/bloc/pantry_event.dart';
import '../../core/di/household_id_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;
  bool _isLookingUp = false;
  String? _scannedBarcode;
  String? _lookupError;

  // Form controllers — shown after scan
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  DateTime? _selectedExpiry;

  @override
  void dispose() {
    _scannerController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // ── Barcode detected ───────────────────────────────────────────────────────
  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (!_isScanning) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    setState(() {
      _isScanning = false;
      _isLookingUp = true;
      _scannedBarcode = barcode;
      _lookupError = null;
    });

    await _scannerController.stop();
    await _lookupProduct(barcode);
  }

  // ── Open Food Facts lookup ─────────────────────────────────────────────────
  Future<void> _lookupProduct(String barcode) async {
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );
      final response = await http.get(url).timeout(
        const Duration(seconds: 6),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          final name = product['product_name'] ??
              product['product_name_en'] ??
              '';
          setState(() {
            _nameController.text = name.isNotEmpty ? name : '';
            _isLookingUp = false;
          });
          return;
        }
      }
      // Product not found in database
      setState(() {
        _isLookingUp = false;
        _nameController.text = '';
      });
    } catch (_) {
      setState(() {
        _isLookingUp = false;
        _nameController.text = '';
        _lookupError = 'Could not look up product. Enter name manually.';
      });
    }
  }

  // ── Add item to pantry ────────────────────────────────────────────────────
  void _addItem(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    final householdId = _getHouseholdId(context);
    if (householdId == null) return;

    context.read<PantryBloc>().add(
      PantryItemAdded(
        householdId: householdId,
        name: name,
        barcode: _scannedBarcode,
        quantity: quantity,
        expiryDate: _selectedExpiry,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added to pantry'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    _reset();
  }

  void _reset() {
    setState(() {
      _isScanning = true;
      _isLookingUp = false;
      _scannedBarcode = null;
      _lookupError = null;
      _selectedExpiry = null;
      _nameController.clear();
      _quantityController.text = '1';
    });
    _scannerController.start();
  }

  String? _getHouseholdId(BuildContext context) {
    // Gets the householdId that was used to start PantryBloc
    // We read it from the bloc's last started event via a simple workaround
    final state = context.read<PantryBloc>().state;
    // householdId is stored in MainShell — pass via inherited or read from
    // Firestore cache. For now, read from the app's service locator pattern.
    // We'll resolve this cleanly in the next step.
    return _householdIdFromContext(context);
  }

  String? _householdIdFromContext(BuildContext context) {
    // Walk up the widget tree to find MainShell's household id
    // This is set via InheritedWidget in the next step.
    // Temporary: return null-safe fallback
    try {
      return HouseholdIdProvider.of(context);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
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
    if (picked != null) {
      setState(() => _selectedExpiry = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isScanning || _isLookingUp
          ? _ScannerView(
              controller: _scannerController,
              isLookingUp: _isLookingUp,
              onDetected: _onBarcodeDetected,
              onManualAdd: () => setState(() {
                _isScanning = false;
                _isLookingUp = false;
              }),
            )
          : _ItemForm(
              nameController: _nameController,
              quantityController: _quantityController,
              barcode: _scannedBarcode,
              lookupError: _lookupError,
              selectedExpiry: _selectedExpiry,
              onPickExpiry: _pickExpiryDate,
              onAdd: () => _addItem(context),
              onReset: _reset,
            ),
    );
  }
}

// ── Scanner view ──────────────────────────────────────────────────────────────

class _ScannerView extends StatelessWidget {
  final MobileScannerController controller;
  final bool isLookingUp;
  final Function(BarcodeCapture) onDetected;
  final VoidCallback onManualAdd;

  const _ScannerView({
    required this.controller,
    required this.isLookingUp,
    required this.onDetected,
    required this.onManualAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera feed
        MobileScanner(
          controller: controller,
          onDetect: onDetected,
        ),

        // Dark overlay with cut-out
        CustomPaint(
          painter: _ScanOverlayPainter(),
          child: const SizedBox.expand(),
        ),

        // Top label
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLookingUp ? 'Looking up product...' : 'Point at a barcode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Loading spinner
        if (isLookingUp)
          const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),

        // Manual add button at bottom
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: onManualAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Add manually instead',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Scan overlay painter ──────────────────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cutoutSize = 260.0;
    final cutoutLeft = (size.width - cutoutSize) / 2;
    final cutoutTop = (size.height - cutoutSize) / 2 - 40;
    final cutoutRect = Rect.fromLTWH(
      cutoutLeft,
      cutoutTop,
      cutoutSize,
      cutoutSize,
    );

    final paint = Paint()..color = Colors.black54;

    // Draw dark overlay with hole
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(cutoutRect, const Radius.circular(12)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const bracketLength = 24.0;

    // Top-left
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + bracketLength),
      Offset(cutoutLeft, cutoutTop),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop),
      Offset(cutoutLeft + bracketLength, cutoutTop),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize - bracketLength, cutoutTop),
      Offset(cutoutLeft + cutoutSize, cutoutTop),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize, cutoutTop),
      Offset(cutoutLeft + cutoutSize, cutoutTop + bracketLength),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + cutoutSize - bracketLength),
      Offset(cutoutLeft, cutoutTop + cutoutSize),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + cutoutSize),
      Offset(cutoutLeft + bracketLength, cutoutTop + cutoutSize),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize - bracketLength, cutoutTop + cutoutSize),
      Offset(cutoutLeft + cutoutSize, cutoutTop + cutoutSize),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize, cutoutTop + cutoutSize - bracketLength),
      Offset(cutoutLeft + cutoutSize, cutoutTop + cutoutSize),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Item form ─────────────────────────────────────────────────────────────────

class _ItemForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final String? barcode;
  final String? lookupError;
  final DateTime? selectedExpiry;
  final VoidCallback onPickExpiry;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  const _ItemForm({
    required this.nameController,
    required this.quantityController,
    required this.barcode,
    required this.lookupError,
    required this.selectedExpiry,
    required this.onPickExpiry,
    required this.onAdd,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add item', style: AppTextStyles.heading1),
              GestureDetector(
                onTap: onReset,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Scan again',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (barcode != null) ...[
            const SizedBox(height: 8),
            Text(
              'Barcode: $barcode',
              style: AppTextStyles.caption,
            ),
          ],

          if (lookupError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                lookupError!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.warningText,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          MiseTextField(
            label: 'Item name',
            placeholder: 'e.g. Oat Milk',
            controller: nameController,
          ),

          MiseTextField(
            label: 'Quantity',
            placeholder: '1',
            controller: quantityController,
            keyboardType: TextInputType.number,
          ),

          // Expiry date picker
          Text('EXPIRY DATE'.toUpperCase(),
              style: AppTextStyles.label),
          const SizedBox(height: 6),
          MiseCard(
            onTap: onPickExpiry,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedExpiry == null
                      ? 'Optional — tap to set'
                      : '${selectedExpiry!.day}/${selectedExpiry!.month}/${selectedExpiry!.year}',
                  style: AppTextStyles.body.copyWith(
                    color: selectedExpiry == null
                        ? AppColors.textDisabled
                        : AppColors.textPrimary,
                  ),
                ),
                Icon(
                  selectedExpiry == null
                      ? Icons.calendar_today_outlined
                      : Icons.edit_calendar_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          MiseButton(label: 'Add to pantry', onTap: onAdd),
        ],
      ),
    );
  }
}