// Event Request Model - Data Layer
import '../../domain/entities/event_request_entity.dart';
import '../../domain/entities/event_request_status.dart';

class EventRequestModel extends EventRequestEntity {
  const EventRequestModel({
    required super.id,
    required super.requesterId,
    required super.type,
    required super.decorated,
    super.hallId,
    required super.branchId,
    required super.startTime,
    required super.durationHours,
    required super.persons,
    super.addOns,
    super.notes,
    required super.status,
    super.quotedPrice,
    required super.createdAt,
    required super.updatedAt,
  });

  factory EventRequestModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      return int.tryParse(s ?? '') ?? 0;
    }

    double? asDoubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      final s = v?.toString();
      return double.tryParse(s ?? '');
    }

    DateTime asDate(dynamic v) {
      if (v is DateTime) return v;
      return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
    }

    List<Map<String, dynamic>>? parseAddOns(dynamic v) {
      if (v == null) return null;
      if (v is List) {
        return v.map((e) {
          if (e is Map<String, dynamic>) return e;
          return Map<String, dynamic>.from(e as Map);
        }).toList();
      }
      return null;
    }

    return EventRequestModel(
      id: json['id'] as String,
      requesterId: json['requesterId'] as String,
      type: json['type'] as String,
      decorated: json['decorated'] as bool? ?? false,
      hallId: json['hallId'] as String?,
      branchId: json['branchId'] as String,
      startTime: asDate(json['startTime']),
      durationHours: asInt(json['durationHours']),
      persons: asInt(json['persons']),
      addOns: parseAddOns(json['addOns']),
      notes: json['notes'] as String?,
      status: EventRequestStatus.fromString(json['status'] as String),
      quotedPrice: asDoubleOrNull(json['quotedPrice']),
      createdAt: asDate(json['createdAt']),
      updatedAt: asDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'type': type,
      'decorated': decorated,
      'hallId': hallId,
      'branchId': branchId,
      'startTime': startTime.toIso8601String(),
      'durationHours': durationHours,
      'persons': persons,
      'addOns': addOns,
      'notes': notes,
      'status': status.toApiString(),
      'quotedPrice': quotedPrice,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

