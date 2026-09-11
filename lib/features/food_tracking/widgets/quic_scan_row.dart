import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitflow/core/utils/date_utils.dart';
import 'package:habitflow/features/food_tracking/widgets/food_camera_screen.dart';

class QuickScanRow extends ConsumerWidget {
  final DateTime day;
  const QuickScanRow({super.key, required this.day});

  void _openInAppCamera(BuildContext context) {
    // Always use the latest normalized date when opening the camera
    final normalizedDay = DateTime.now().normalized;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodCameraScreen(day: normalizedDay),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openInAppCamera(context),
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Scan food'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: scheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/barcode'),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: const Text('Barcode'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: scheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
