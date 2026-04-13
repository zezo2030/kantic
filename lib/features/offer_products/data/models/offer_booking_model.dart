import '../../../../core/utils/api_json.dart';
import '../../domain/entities/offer_booking_entity.dart';

class OfferBookingModel extends OfferBookingEntity {
  const OfferBookingModel({
    required super.id,
    required super.userId,
    required super.branchId,
    required super.offerProductId,
    required super.offerSnapshot,
    super.selectedAddOns,
    required super.subtotal,
    required super.addonsTotal,
    required super.totalPrice,
    required super.paymentStatus,
    required super.status,
    super.contactPhone,
  });

  factory OfferBookingModel.fromJson(Map<String, dynamic> json) {
    return OfferBookingModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      offerProductId: json['offerProductId']?.toString() ?? '',
      offerSnapshot: asJsonMap(json['offerSnapshot']),
      selectedAddOns: json['selectedAddOns'],
      subtotal: toDouble(json['subtotal']) ?? 0,
      addonsTotal: toDouble(json['addonsTotal']) ?? 0,
      totalPrice: toDouble(json['totalPrice']) ?? 0,
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      status: json['status']?.toString() ?? 'active',
      contactPhone: json['contactPhone']?.toString(),
    );
  }
}
