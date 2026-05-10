import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum ScanContext { shopping, pantry }

/// Shows the scan bottom sheet and returns the product name if found.
/// Returns null if dismissed without a result.
Future<String?> showScanBottomSheet(
  BuildContext context, {
  required ScanContext scanContext,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScanSheet(scanContext: scanContext),
  );
}

class _ScanSheet extends StatefulWidget {
  final ScanContext scanContext;
  const _ScanSheet({required this.scanContext});

  @override
  State<_ScanSheet> createState() => _ScanSheetState();
}

class _ScanSheetState extends State<_ScanSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  String? _statusMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() {
      _processing = true;
      _statusMessage = 'Looking up product...';
    });
    await _controller.stop();

    final code = barcode!.rawValue!;
    final name = await _lookupBarcode(code);

    if (!mounted) return;

    if (name != null) {
      Navigator.of(context).pop(name);
    } else {
      setState(() {
        _statusMessage = 'Product not found. Try another barcode.';
        _processing = false;
      });
      await _controller.start();
    }
  }

  Future<String?> _lookupBarcode(String barcode) async {
    try {
      final uri = Uri.parse(
          'https://world.openfoodfacts.org/api/v2/product/$barcode?fields=product_name');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final name = data['product']?['product_name'] as String?;
        return (name != null && name.isNotEmpty) ? name : null;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.scanContext == ScanContext.shopping
        ? 'Add to shopping list'
        : 'Add to pantry';

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(label, style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          Text('Point camera at barcode', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                  // viewfinder overlay
                  Center(
                    child: Container(
                      width: 220,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_statusMessage != null)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_statusMessage!,
                              style: AppTextStyles.body),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}