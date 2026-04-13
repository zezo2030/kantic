// Ticket Model - Data Layer
import '../../domain/entities/ticket_entity.dart';

class TicketModel extends TicketEntity {
  const TicketModel({
    required super.id,
    required super.bookingId,
    required super.status,
    super.scannedAt,
    super.holderName,
    super.holderPhone,
    required super.personCount,
    super.validFrom,
    super.validUntil,
    required super.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, [int fallback = 1]) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      return int.tryParse(s ?? '') ?? fallback;
    }

    DateTime? asDateOrNull(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return TicketModel(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      status: json['status'] as String,
      scannedAt: asDateOrNull(json['scannedAt']),
      holderName: json['holderName'] as String?,
      holderPhone: json['holderPhone'] as String?,
      personCount: asInt(json['personCount'], 1),
      validFrom: asDateOrNull(json['validFrom']),
      validUntil: asDateOrNull(json['validUntil']),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
