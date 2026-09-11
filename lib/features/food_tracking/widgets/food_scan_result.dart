import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/features/food_tracking/providers/food_tracking_provider.dart';
import '../../../data/models/tracking_models.dart';
import 'scan_capture_animation.dart';

/// Bottom sheet shown after a photo scan. Nothing is saved until the user
/// taps "Add all" — items can be reviewed and removed first.
class FoodScanResultSheet extends ConsumerStatefulWidget {
  final File image;
  final DateTime day;
  const FoodScanResultSheet(
      {super.key, required this.image, required this.day});

  @override
  ConsumerState<FoodScanResultSheet> createState() =>
      _FoodScanResultSheetState();
}

class _FoodScanResultSheetState extends ConsumerState<FoodScanResultSheet> {
  List<FoodEntry>? _editable;

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(aiFoodScanProvider(widget.image));
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.62,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => scan.when(
          loading: () => _Loading(image: widget.image),
          error: (e, _) => _Error(message: '$e'),
          data: (results) {
            _editable ??= List.of(results);
            if (_editable!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                    'No food detected — try a clearer photo or add manually.'),
              );
            }
            final total = _editable!.fold<double>(0, (s, e) => s + e.calories);
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(children: [
                  Text('Detected items', style: text.titleLarge),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text('${total.round()} kcal',
                        style: text.labelMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  itemCount: _editable!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _DetectedItem(
                    entry: _editable![i],
                    onRemove: () => setState(() => _editable!.removeAt(i)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (_editable != null && _editable!.isNotEmpty) {
                      await ref
                          .read(foodLogProvider(widget.day).notifier)
                          .addEntries(_editable!);
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text('Add all (${_editable!.length})'),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  final File image;
  const _Loading({required this.image});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        FoodScanAnimation(image: image),
        const SizedBox(height: 20),
        Text('Analyzing your photo…', style: text.bodyLarge),
        const SizedBox(height: 4),
        Text('Identifying ingredients and portions', style: text.bodyMedium),
      ]),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  const _Error({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 40),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close')),
      ]),
    );
  }
}

class _DetectedItem extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onRemove;
  const _DetectedItem({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(11)),
          child: Icon(mealIcons[entry.mealType] ?? Icons.restaurant,
              color: scheme.onSecondaryContainer, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.name, style: text.titleMedium),
            const SizedBox(height: 2),
            Wrap(spacing: 6, children: [
              _Badge(text: '${entry.calories.round()} kcal'),
              if (entry.servingSize != null)
                _Badge(text: '${entry.servingSize!.round()}g'),
              if (entry.fiber != null)
                _Badge(text: '${entry.fiber!.toStringAsFixed(1)}g fiber'),
            ]),
          ]),
        ),
        IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: onRemove),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
