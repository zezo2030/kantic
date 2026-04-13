import 'package:equatable/equatable.dart';

class OfferBookingEntity extends Equatable {
  final String id;
  final String userId;
  final String branchId;
  final String offerProductId;
  final Map<String, dynamic> offerSnapshot;
  final dynamic selectedAddOns;
  final double subtotal;
  final double addonsTotal;
  final double totalPrice;
  final String paymentStatus;
  final String status;
  final String? contactPhone;

  const OfferBookingEntity({
    required this.id,
    required this.userId,
    required this.branchId,
    required this.offerProductId,
    required this.offerSnapshot,
    this.selectedAddOns,
    required this.subtotal,
    required this.addonsTotal,
    required this.totalPrice,
    required this.paymentStatus,
    required this.status,
    this.contactPhone,
  });

  String get title =>
      (offerSnapshot['title'] ?? offerSnapshot['offerTitle'] ?? '')
          .toString();

  @override
  List<Object?> get props => [id, status, paymentStatus];
}
