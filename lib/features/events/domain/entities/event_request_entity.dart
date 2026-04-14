// Event Request Entity - Domain Layer
import 'package:equatable/equatable.dart';
import 'event_request_status.dart';

class EventRequestEntity extends Equatable {
  final String id;
  final String requesterId;
  final String type;
  final bool decorated;
  final String? hallId;
  final String branchId;
  final DateTime startTime;
  final int durationHours;
  final int persons;
  final String? selectedTimeSlot;
  final List<Map<String, dynamic>>? addOns;
  final String? notes;
  final EventRequestStatus status;
  final String? paymentOption;
  final double? quotedPrice;
  final double? totalPrice;
  final double? depositAmount;
  final double? amountPaid;
  final double? remainingAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventRequestEntity({
    required this.id,
    required this.requesterId,
    required this.type,
    required this.decorated,
    this.hallId,
    required this.branchId,
    required this.startTime,
    required this.durationHours,
    required this.persons,
    this.selectedTimeSlot,
    this.addOns,
    this.notes,
    required this.status,
    this.paymentOption,
    this.quotedPrice,
    this.totalPrice,
    this.depositAmount,
    this.amountPaid,
    this.remainingAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    requesterId,
    type,
    decorated,
    hallId,
    branchId,
    startTime,
    durationHours,
    persons,
    selectedTimeSlot,
    addOns,
    notes,
    status,
    paymentOption,
    quotedPrice,
    totalPrice,
    depositAmount,
    amountPaid,
    remainingAmount,
    createdAt,
    updatedAt,
  ];
}
