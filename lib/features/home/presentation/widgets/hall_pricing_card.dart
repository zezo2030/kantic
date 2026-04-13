import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/branch_entity.dart';

class BranchPricingCard extends StatelessWidget {
  final BranchEntity branch;

  const BranchPricingCard({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    final priceConfig = branch.priceConfig;
    if (priceConfig == null) {
      return const SizedBox.shrink();
    }
    final basePrice = (priceConfig['basePrice'] as num?)?.toDouble() ?? 0.0;
    final hourlyRate = (priceConfig['hourlyRate'] as num?)?.toDouble() ?? 0.0;
    final pricePerPerson =
        (priceConfig['pricePerPerson'] as num?)?.toDouble() ?? 0.0;
    final weekendMultiplier =
        (priceConfig['weekendMultiplier'] as num?)?.toDouble() ?? 1.0;
    final holidayMultiplier =
        (priceConfig['holidayMultiplier'] as num?)?.toDouble() ?? 1.0;
    final decorationPrice =
        (priceConfig['decorationPrice'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.dollar_circle,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'pricing_info'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Base price
            _buildPriceRow(
              context,
              'base_price'.tr(),
              '$basePrice ${'currency'.tr()}',
              Iconsax.calendar_1,
            ),

            const SizedBox(height: 12),

            // Hourly rate
            _buildPriceRow(
              context,
              'hourly_rate'.tr(),
              '$hourlyRate ${'currency'.tr()} ${'per_hour'.tr()}',
              Iconsax.clock,
            ),

            const SizedBox(height: 12),

            // Price per person
            if (pricePerPerson > 0)
              _buildPriceRow(
                context,
                'price_per_person'.tr(),
                '$pricePerPerson ${'currency'.tr()} ${'per_person'.tr()}',
                Iconsax.people,
              ),

            if (pricePerPerson > 0) const SizedBox(height: 12),

            // Weekend pricing
            if (weekendMultiplier > 1.0)
              _buildPriceRow(
                context,
                'weekend_price'.tr(),
                '${(hourlyRate * weekendMultiplier).toStringAsFixed(0)} ${'currency'.tr()} ${'per_hour'.tr()}',
                Iconsax.calendar_2,
                subtitle:
                    '${(weekendMultiplier * 100).toStringAsFixed(0)}% ${'increase'.tr()}',
              ),

            if (weekendMultiplier > 1.0) const SizedBox(height: 12),

            // Holiday pricing
            if (holidayMultiplier > 1.0)
              _buildPriceRow(
                context,
                'holiday_price'.tr(),
                '${(hourlyRate * holidayMultiplier).toStringAsFixed(0)} ${'currency'.tr()} ${'per_hour'.tr()}',
                Iconsax.cake,
                subtitle:
                    '${(holidayMultiplier * 100).toStringAsFixed(0)}% ${'increase'.tr()}',
              ),

            if (holidayMultiplier > 1.0) const SizedBox(height: 12),

            // Decoration price
            if (decorationPrice > 0)
              _buildPriceRow(
                context,
                'decoration_price'.tr(),
                '$decorationPrice ${'currency'.tr()}',
                Iconsax.star_1,
                subtitle: 'optional'.tr(),
              ),

            const SizedBox(height: 16),

            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.info_circle,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'pricing_note'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String title,
    String price,
    IconData icon, {
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
