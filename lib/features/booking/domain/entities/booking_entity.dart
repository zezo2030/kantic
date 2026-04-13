// Booking Entity - Domain Layer
import 'package:equatable/equatable.dart';

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
      ];
}
