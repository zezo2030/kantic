// AddOns Selector Widget - Presentation Layer
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/addon_entity.dart';

class AddOnsSelector extends StatefulWidget {
  final List<AddOnEntity> availableAddOns;
  final List<String> selectedAddOnIds;
  final Function(List<String>) onAddOnsChanged;

  const AddOnsSelector({
    super.key,
    required this.availableAddOns,
    required this.selectedAddOnIds,
    required this.onAddOnsChanged,
  });

  @override
  State<AddOnsSelector> createState() => _AddOnsSelectorState();
}

class _AddOnsSelectorState extends State<AddOnsSelector> {
  final Map<String, int> _addOnQuantities = {};

  @override
  void initState() {
    super.initState();
    // Initialize quantities for selected add-ons
    for (final addOnId in widget.selectedAddOnIds) {
      _addOnQuantities[addOnId] = 1;
    }
  }

  void _toggleAddOn(String addOnId, bool isSelected) {
    setState(() {
      if (isSelected) {
        widget.selectedAddOnIds.add(addOnId);
        _addOnQuantities[addOnId] = 1;
      } else {
        widget.selectedAddOnIds.remove(addOnId);
        _addOnQuantities.remove(addOnId);
      }
    });
    widget.onAddOnsChanged(widget.selectedAddOnIds);
  }

  void _updateQuantity(String addOnId, int quantity) {
    if (quantity <= 0) {
      _toggleAddOn(addOnId, false);
    } else {
      setState(() {
        _addOnQuantities[addOnId] = quantity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableAddOns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.add_square, size: 20),
                const SizedBox(width: 8),
                Text(
                  'add_ons'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.availableAddOns.map((addOn) => _buildAddOnItem(addOn)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOnItem(AddOnEntity addOn) {
    final isSelected = widget.selectedAddOnIds.contains(addOn.id);
    final quantity = _addOnQuantities[addOn.id] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.05)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleAddOn(addOn.id, value ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addOn.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${addOn.price} ${'currency'.tr()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('quantity'.tr()),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _updateQuantity(addOn.id, quantity - 1),
                      icon: const Icon(Iconsax.minus),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$quantity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _updateQuantity(addOn.id, quantity + 1),
                      icon: const Icon(Iconsax.add),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${'total'.tr()}: ${(addOn.price * quantity).toStringAsFixed(2)} ${'currency'.tr()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
