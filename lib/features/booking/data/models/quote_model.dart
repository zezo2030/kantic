// Quote Model - Data Layer
import '../../domain/entities/quote_entity.dart';

class QuoteModel extends QuoteEntity {
  const QuoteModel({
    required super.branchId,
    required super.branchName,
    required super.pricing,
    required super.addOns,
    required super.discount,
    required super.totalPrice,
    required super.available,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    // معالجة بيانات التسعير من الباك إند
    final pricing = json['pricing'] as Map<String, dynamic>? ?? {};

    double readNum(
      Map<String, dynamic> map,
      List<String> keys, {
      double defaultValue = 0.0,
    }) {
      for (final k in keys) {
        if (map.containsKey(k) && map[k] != null) {
          final v = map[k];
          if (v is num) return v.toDouble();
          if (v is String) {
            final parsed = double.tryParse(v);
            if (parsed != null) return parsed;
          }
        }
      }
      return defaultValue;
    }

    // استخراج جميع حقول التسعير من الباك إند مع دعم مفاتيح بديلة
    final processedPricing = <String, dynamic>{
      'basePrice': readNum(pricing, ['basePrice', 'base_price', 'base']),
      'hourlyPrice': readNum(pricing, [
        'hourlyPrice',
        'hourly_price',
        'totalHourly',
        'hoursTotal',
      ]),
      'hourlyRate': readNum(pricing, [
        'hourlyRate',
        'hourly_rate',
        'perHour',
        'per_hour',
        'hour_rate',
      ]),
      'pricePerPerson': readNum(pricing, [
        'pricePerPerson',
        'price_per_person',
        'perPerson',
        'per_person',
      ]),
      'personsPrice': readNum(pricing, [
        'personsPrice',
        'persons_price',
        'peopleTotal',
        'persons_total',
      ]),
      'multiplier': readNum(pricing, [
        'multiplier',
        'dayMultiplier',
        'factor',
      ], defaultValue: 1.0),
      'decorationPrice': readNum(pricing, [
        'decorationPrice',
        'decoration_price',
        'decorPrice',
        'decor_price',
      ]),
      'totalPrice': readNum(pricing, [
        'totalPrice',
        'total_price',
        'grandTotal',
      ]),
    };

    // معلومات تشخيصية للتحقق من البيانات

    return QuoteModel(
      branchId: json['branchId'] as String? ?? json['hallId'] as String? ?? '',
      branchName: json['branchName'] as String? ?? json['hallName'] as String? ?? '',
      pricing: processedPricing,
      addOns: List<Map<String, dynamic>>.from(json['addOns'] ?? []),
      discount: (json['discount'] as num? ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] as num? ?? 0).toDouble(),
      available: json['available'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'pricing': pricing,
      'addOns': addOns,
      'discount': discount,
      'totalPrice': totalPrice,
      'available': available,
    };
  }
}
