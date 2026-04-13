// Ticket Entity - Domain Layer
import 'package:equatable/equatable.dart';

class TicketEntity extends Equatable {
  final String id;
  final String bookingId;
  final String status; // valid | used | cancelled
  final DateTime? scannedAt;
  final String? holderName;
  final String? holderPhone;
  final int personCount;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime createdAt;

  const TicketEntity({
    required this.id,
    required this.bookingId,
    required this.status,
    this.scannedAt,
    this.holderName,
    this.holderPhone,
    required this.personCount,
    this.validFrom,
    this.validUntil,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    bookingId,
    status,
    scannedAt,
    holderName,
    holderPhone,
    personCount,
    validFrom,
    validUntil,
    createdAt,
  ];
}
