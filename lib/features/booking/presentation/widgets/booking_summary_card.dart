// Booking Summary Card Widget - Presentation Layer
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/quote_entity.dart';

class BookingSummaryCard extends StatelessWidget {
  final String hallName;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final int durationHours;
  final int personsCount;
  final QuoteEntity? quote;
  final String? couponCode;
  final List<Map<String, dynamic>>? selectedAddOns;
  final String? specialRequests;
  final String? contactPhone;

  const BookingSummaryCard({
    super.key,
    required this.hallName,
    required this.selectedDate,
    required this.selectedTime,
    required this.durationHours,
    required this.personsCount,
    this.quote,
    this.couponCode,
    this.selectedAddOns,
    this.specialRequests,
    this.contactPhone,
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
            Row(
              children: [
                const Icon(Iconsax.document_text, size: 20),
                const SizedBox(width: 8),
                Text(
                  'booking_summary'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(context, 'hall'.tr(), hallName, Iconsax.home_2),
            const SizedBox(height: 8),
            _buildSummaryItem(
              context,
              'date'.tr(),
              selectedDate != null
                  ? DateFormat('yyyy/MM/dd').format(selectedDate!)
                  : 'not_selected'.tr(),
              Iconsax.calendar_1,
            ),
            const SizedBox(height: 8),
            _buildSummaryItem(
              context,
              'time'.tr(),
              selectedTime != null
                  ? selectedTime!.format(context)
                  : 'not_selected'.tr(),
              Iconsax.clock,
            ),
            const SizedBox(height: 8),
            _buildSummaryItem(
              context,
              'duration'.tr(),
              '$durationHours ${'hours'.tr()}',
              Iconsax.timer,
            ),
            const SizedBox(height: 8),
            _buildSummaryItem(
              context,
              'persons'.tr(),
              '$personsCount ${'persons'.tr()}',
              Iconsax.people,
            ),
            if (couponCode != null) ...[
              const SizedBox(height: 8),
              _buildSummaryItem(
                context,
                'coupon_code'.tr(),
                couponCode!,
                Iconsax.discount_shape,
                color: Colors.green,
              ),
            ],
            if (selectedAddOns != null && selectedAddOns!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSummaryItem(
                context,
                'add_ons'.tr(),
                '${selectedAddOns!.length} ${'items'.tr()}',
                Iconsax.add_square,
              ),
            ],
            if (specialRequests != null && specialRequests!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSummaryItem(
                context,
                'special_requests'.tr(),
                specialRequests!,
                Iconsax.note_text,
              ),
            ],
            if (contactPhone != null) ...[
              const SizedBox(height: 8),
              _buildSummaryItem(
                context,
                'contact_phone'.tr(),
                contactPhone!,
                Iconsax.call,
              ),
            ],
            // عرض السعر الإجمالي
            if (quote != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildSummaryItem(
                context,
                'total_price'.tr(),
                '${quote!.totalPrice.toStringAsFixed(2)} ${'currency'.tr()}',
                Iconsax.dollar_circle,
                color: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  // تم إزالة دوال ملخص السعر (_buildPriceSummary و _buildPriceRow) لعدم الحاجة إليها

  // تم إزالة دوال المساعدة الخاصة بملخص السعر لعدم استخدامها
}
