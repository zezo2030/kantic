// Booking Entity - Domain Layer
import 'package:equatable/equatable.dart';

class BookingTicketRef extends Equatable {
  final String id;
  final String status;
  final Map<String, dynamic>? metadata;

  const BookingTicketRef({
    required this.id,
    required this.status,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, status, metadata];
}

class BookingEntity extends Equatable {
  final String id;
  final String userId;
  final String branchId;
  final DateTime startTime;
  final int durationHours;
  final int persons;
  final double totalPrice;
  final String status;
  final String? couponCode;
  final double? discountAmount;
  final String? specialRequests;
  final String? contactPhone;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final String? branchNameAr;
  final String? branchNameEn;
  final List<BookingTicketRef> ticketRefs;

  const BookingEntity({
    required this.id,
    required this.userId,
    required this.branchId,
    required this.startTime,
    required this.durationHours,
    required this.persons,
    required this.totalPrice,
    required this.status,
    this.couponCode,
    this.discountAmount,
    this.specialRequests,
    this.contactPhone,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.branchNameAr,
    this.branchNameEn,
    this.ticketRefs = const [],
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        branchId,
        startTime,
        durationHours,
        persons,
        totalPrice,
        status,
        couponCode,
        discountAmount,
        specialRequests,
        contactPhone,
        cancelledAt,
        cancellationReason,
        createdAt,
        updatedAt,
        metadata,
        branchNameAr,
        branchNameEn,
        ticketRefs,
      ];
}
