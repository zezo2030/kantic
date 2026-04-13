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
  final List<Map<String, dynamic>>? addOns;
  final String? notes;
  final EventRequestStatus status;
  final double? quotedPrice;
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
    this.addOns,
    this.notes,
    required this.status,
    this.quotedPrice,
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
        addOns,
        notes,
        status,
        quotedPrice,
        createdAt,
        updatedAt,
      ];
}

