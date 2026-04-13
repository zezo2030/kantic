// Duration Selector Widget - Presentation Layer
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';

class DurationSelector extends StatelessWidget {
  final int selectedDuration;
  final Function(int) onDurationChanged;
  final int? maxDuration; // حد أعلى اختياري اعتماداً على ساعات العمل

  const DurationSelector({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
    this.maxDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'duration'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Iconsax.clock, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('$selectedDuration ${'hours'.tr()}')),
                Row(
                  children: [
                    IconButton(
                      onPressed: selectedDuration > 1
                          ? () => onDurationChanged(selectedDuration - 1)
                          : null,
                      icon: const Icon(Iconsax.minus),
                      style: IconButton.styleFrom(
                        backgroundColor: selectedDuration > 1
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed:
                          (maxDuration == null
                              ? selectedDuration < 12
                              : selectedDuration < maxDuration!)
                          ? () => onDurationChanged(selectedDuration + 1)
                          : null,
                      icon: const Icon(Iconsax.add),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            (maxDuration == null
                                ? selectedDuration < 12
                                : selectedDuration < maxDuration!)
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.grey.shade200,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (maxDuration != null)
              Text(
                '${'max'.tr()}: $maxDuration ${'hours'.tr()}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              )
            else
              Text(
                'duration_note'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}
