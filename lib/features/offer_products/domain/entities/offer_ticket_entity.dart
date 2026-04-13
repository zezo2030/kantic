import 'package:equatable/equatable.dart';

class OfferTicketEntity extends Equatable {
  final String id;
  final String offerBookingId;
  final String ticketKind;
  final String status;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? scannedAt;
  final String? qrData;

  const OfferTicketEntity({
    required this.id,
    required this.offerBookingId,
    required this.ticketKind,
    required this.status,
    this.startedAt,
    this.expiresAt,
    this.scannedAt,
    this.qrData,
  });

  @override
  List<Object?> get props => [id, status];
}
