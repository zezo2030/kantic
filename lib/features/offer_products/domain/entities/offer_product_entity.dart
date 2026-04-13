import 'package:equatable/equatable.dart';

class OfferProductEntity extends Equatable {
  final String id;
  final String branchId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? termsAndConditions;
  final String offerCategory;
  final double price;
  final String currency;
  final bool isGiftable;
  final bool canRepeatInSameOrder;
  final Map<String, dynamic>? ticketConfig;
  final Map<String, dynamic>? hoursConfig;
  final List<Map<String, dynamic>> includedAddOns;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const OfferProductEntity({
    required this.id,
    required this.branchId,
    required this.title,
    this.description,
    this.imageUrl,
    this.termsAndConditions,
    required this.offerCategory,
    required this.price,
    required this.currency,
    required this.isGiftable,
    required this.canRepeatInSameOrder,
    this.ticketConfig,
    this.hoursConfig,
    this.includedAddOns = const [],
    this.startsAt,
    this.endsAt,
  });

  @override
  List<Object?> get props => [id, offerCategory, price];
}
