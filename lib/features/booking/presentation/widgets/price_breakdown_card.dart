// Price Breakdown Card Widget - Presentation Layer
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/quote_entity.dart';

class PriceBreakdownCard extends StatelessWidget {
  final QuoteEntity? quote;
  final bool isLoading;
  final int durationHours; // إضافة المدة كمعامل منفصل

  const PriceBreakdownCard({
    super.key,
    this.quote,
    this.isLoading = false,
    required this.durationHours, // جعل المدة مطلوبة
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Iconsax.dollar_circle, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'price_breakdown'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    }

    if (quote == null) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Iconsax.dollar_circle, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'price_breakdown'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'complete_booking_details'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
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
                const Icon(Iconsax.dollar_circle, size: 20),
                const SizedBox(width: 8),
                Text(
                  'price_breakdown'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // القسم الأول: معلومات التسعير الأساسية
            Text(
              'pricing_details'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),

            // السعر الأساسي الثابت
            _buildPriceRow(
              context,
              'base_price'.tr(),
              '${_getBasePrice()} ${'currency'.tr()}',
              Iconsax.home_2,
              color: Colors.green,
            ),
            const SizedBox(height: 8),

            // السعر بالساعة
            _buildPriceRow(
              context,
              'hourly_rate'.tr(),
              '${_computeHourlyRate()} ${'currency'.tr()} ${'per_hour'.tr()}',
              Iconsax.clock,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),

            // عدد الساعات
            _buildPriceRow(
              context,
              'duration'.tr(),
              '$durationHours ${'hours'.tr()}',
              Iconsax.timer,
            ),
            const SizedBox(height: 8),

            // السعر الإجمالي للساعات
            _buildPriceRow(
              context,
              'hourly_price'.tr(),
              '${_computeHourlyTotal()} ${'currency'.tr()}',
              Iconsax.calculator,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),

            // السعر لكل شخص
            if (_getPricePerPerson() > 0) ...[
              _buildPriceRow(
                context,
                'price_per_person'.tr(),
                '${_getPricePerPerson()} ${'currency'.tr()} ${'per_person'.tr()}',
                Iconsax.people,
                color: Colors.teal,
              ),
              const SizedBox(height: 8),

              // السعر الإجمالي للأشخاص
              _buildPriceRow(
                context,
                'persons_total_price'.tr(),
                '${_getPersonsPrice()} ${'currency'.tr()}',
                Iconsax.people,
                color: Colors.teal.shade700,
              ),
              const SizedBox(height: 8),
            ],
            // القسم الثاني: الإضافات والتحسينات
            if (_getDecorationPrice() > 0 || quote!.addOns.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'additions_enhancements'.tr(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
              const SizedBox(height: 12),

              // سعر الديكور إذا كان موجود
              if (_getDecorationPrice() > 0) ...[
                _buildPriceRow(
                  context,
                  'decoration_price'.tr(),
                  '${_getDecorationPrice()} ${'currency'.tr()}',
                  Iconsax.paintbucket,
                  color: Colors.purple,
                ),
                const SizedBox(height: 8),
              ],

              // الإضافات
              if (quote!.addOns.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Iconsax.add_square, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'add_ons'.tr(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...quote!.addOns.map(
                  (addOn) => _buildAddOnPriceRow(context, addOn),
                ),
              ],
            ],
            // القسم الثالث: المضاعفات والخصومات
            if (_getMultiplier() != 1.0 || quote!.discount > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'multipliers_discounts'.tr(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 12),

              // المضاعف
              if (_getMultiplier() != 1.0) ...[
                _buildPriceRow(
                  context,
                  'multiplier'.tr(),
                  '${_getMultiplier().toStringAsFixed(2)}x (${_getMultiplierType()})',
                  Iconsax.calendar,
                  color: Colors.red,
                ),
                const SizedBox(height: 8),
              ],

              // الخصم
              if (quote!.discount > 0) ...[
                _buildPriceRow(
                  context,
                  'discount'.tr(),
                  '-${quote!.discount.toStringAsFixed(2)} ${'currency'.tr()}',
                  Iconsax.discount_shape,
                  color: Colors.green,
                ),
              ],
            ],

            // تم إخفاء قسم معادلة الحساب بناءً على طلب التصميم
            const SizedBox(height: 12),
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 12),

            // السعر النهائي
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: _buildPriceRow(
                context,
                'total_price'.tr(),
                '${quote!.totalPrice.toStringAsFixed(2)} ${'currency'.tr()}',
                Iconsax.calculator,
                isTotal: true,
                color: Colors.blue.shade700,
              ),
            ),
            if (!quote!.available) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.close_circle, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'branch_not_available'.tr(),
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: isTotal ? 20 : 16,
          color: color ?? Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAddOnPriceRow(BuildContext context, Map<String, dynamic> addOn) {
    final name = addOn['name'] ?? '';
    final price = addOn['price'] ?? 0;
    final quantity = addOn['quantity'] ?? 1;
    final total = (price * quantity).toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$name (x$quantity)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '$total ${'currency'.tr()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة للحصول على السعر الأساسي من الباك إند
  String _getBasePrice() {
    if (quote == null) return '0';
    final basePrice = quote!.pricing['basePrice'];
    return basePrice?.toStringAsFixed(2) ?? '0';
  }

  // دالة للحصول على السعر لكل شخص من الباك إند
  double _getPricePerPerson() {
    if (quote == null) return 0.0;
    final pricePerPerson = quote!.pricing['pricePerPerson'];
    return pricePerPerson?.toDouble() ?? 0.0;
  }

  // دالة للحصول على السعر الإجمالي للأشخاص من الباك إند
  String _getPersonsPrice() {
    if (quote == null) return '0';
    final personsPrice = quote!.pricing['personsPrice'];
    return personsPrice?.toStringAsFixed(2) ?? '0';
  }

  double _numOrZero(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  // حساب سعر الساعة مع بدائل: إن لم يتوفر hourlyRate وكان لدينا hourlyPrice والمدة
  String _computeHourlyRate() {
    if (quote == null) return '0.00';
    final hourlyRateRaw = quote!.pricing['hourlyRate'];
    double hourlyRate = _numOrZero(hourlyRateRaw);
    if (hourlyRate == 0.0) {
      final hourlyTotal = _numOrZero(quote!.pricing['hourlyPrice']);
      if (durationHours > 0 && hourlyTotal > 0) {
        hourlyRate = hourlyTotal / durationHours;
      }
    }
    return hourlyRate.toStringAsFixed(2);
  }

  // حساب الإجمالي للساعات مع بدائل: إن لم يتوفر hourlyPrice وكان لدينا hourlyRate والمدة
  String _computeHourlyTotal() {
    if (quote == null) return '0.00';
    double hourlyTotal = _numOrZero(quote!.pricing['hourlyPrice']);
    if (hourlyTotal == 0.0) {
      final hourlyRate = _numOrZero(quote!.pricing['hourlyRate']);
      if (hourlyRate > 0 && durationHours > 0) {
        hourlyTotal = hourlyRate * durationHours;
      }
    }
    return hourlyTotal.toStringAsFixed(2);
  }

  // دالة للحصول على سعر الديكور من الباك إند
  double _getDecorationPrice() {
    if (quote == null) return 0.0;
    final decorationPrice = quote!.pricing['decorationPrice'];
    return decorationPrice?.toDouble() ?? 0.0;
  }

  // دالة للحصول على المضاعف من الباك إند
  double _getMultiplier() {
    if (quote == null) return 1.0;
    final multiplier = quote!.pricing['multiplier'];
    return multiplier?.toDouble() ?? 1.0;
  }

  // دالة لتحديد نوع المضاعف
  String _getMultiplierType() {
    final multiplier = _getMultiplier();
    if (multiplier == 1.0) return 'normal_day'.tr();
    if (multiplier > 1.0) {
      // يمكن تحسين هذا لاحقاً ليتحقق من التاريخ الفعلي
      return 'weekend_day'.tr();
    }
    return 'normal_day'.tr();
  }
}
