import '../../../../core/utils/api_json.dart';
import '../../domain/entities/offer_product_entity.dart';

class OfferProductModel extends OfferProductEntity {
  const OfferProductModel({
    required super.id,
    required super.branchId,
    required super.title,
    super.description,
    super.imageUrl,
    super.termsAndConditions,
    required super.offerCategory,
    required super.price,
    required super.currency,
    required super.isGiftable,
    required super.canRepeatInSameOrder,
    super.ticketConfig,
    super.hoursConfig,
    super.includedAddOns = const [],
    super.startsAt,
    super.endsAt,
  });

  static List<Map<String, dynamic>> _addons(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => asJsonMap(e)).toList();
  }

  factory OfferProductModel.fromJson(Map<String, dynamic> json) {
    return OfferProductModel(
      id: json['id']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      termsAndConditions: json['termsAndConditions']?.toString(),
      offerCategory: json['offerCategory']?.toString() ?? 'ticket_based',
      price: toDouble(json['price']) ?? 0,
      currency: json['currency']?.toString() ?? 'SAR',
      isGiftable: json['isGiftable'] == true,
      canRepeatInSameOrder: json['canRepeatInSameOrder'] != false,
      ticketConfig: json['ticketConfig'] != null
          ? asJsonMap(json['ticketConfig'])
          : null,
      hoursConfig: json['hoursConfig'] != null
          ? asJsonMap(json['hoursConfig'])
          : null,
      includedAddOns: _addons(json['includedAddOns']),
      startsAt: parseDate(json['startsAt']),
      endsAt: parseDate(json['endsAt']),
    );
  }
}
