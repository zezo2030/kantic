// Booking Model - Data Layer
import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.userId,
    required super.branchId,
    required super.startTime,
    required super.durationHours,
    required super.persons,
    required super.totalPrice,
    required super.status,
    super.couponCode,
    super.discountAmount,
    super.specialRequests,
    super.contactPhone,
    super.cancelledAt,
    super.cancellationReason,
    required super.createdAt,
    required super.updatedAt,
    super.metadata,
    super.branchNameAr,
    super.branchNameEn,
    super.ticketRefs,
  });

  static bool _metaBool(Map<String, dynamic>? m, String key) {
    if (m == null) return false;
    final v = m[key];
    return v == true || v == 'true' || v == 1;
  }

  bool get isSchoolTripBooking =>
      metadata != null && metadata!['tripRequestId'] != null;

  bool get isLoyaltyHallTicket =>
      _metaBool(metadata, 'isLoyaltyTicket') ||
      ticketRefs.any((t) => _metaBool(t.metadata, 'isLoyaltyTicket'));

  bool get showInMyHallTicketsList {
    if (isSchoolTripBooking) return false;
    if (status.toLowerCase() == 'cancelled') return false;
    if (isLoyaltyHallTicket) return true;
    final s = status.toLowerCase();
    if (totalPrice == 0 && (s == 'confirmed' || s == 'completed')) {
      return true;
    }
    return false;
  }

  String branchDisplayName(String languageCode) {
    if (languageCode == 'ar') {
      final a = branchNameAr;
      if (a != null && a.isNotEmpty) return a;
      final e = branchNameEn;
      if (e != null && e.isNotEmpty) return e;
    } else {
      final e = branchNameEn;
      if (e != null && e.isNotEmpty) return e;
      final a = branchNameAr;
      if (a != null && a.isNotEmpty) return a;
    }
    return branchId;
  }

  String get primaryTicketId =>
      ticketRefs.isNotEmpty ? ticketRefs.first.id : '';

  String get displayTicketStatus =>
      ticketRefs.isNotEmpty ? ticketRefs.first.status : status;

  DateTime get displayValidUntil =>
      startTime.add(Duration(hours: durationHours));

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v?.toString();
      return int.tryParse(s ?? '') ?? 0;
    }

    double asDouble(dynamic v) {
      if (v is double) return v;
      if (v is num) return v.toDouble();
      final s = v?.toString();
      return double.tryParse(s ?? '') ?? 0.0;
    }

    DateTime asDate(dynamic v) {
      if (v is DateTime) return v;
      return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
    }

    DateTime? asDateOrNull(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    Map<String, dynamic>? meta;
    final rawMeta = json['metadata'];
    if (rawMeta is Map) {
      meta = Map<String, dynamic>.from(rawMeta);
    }

    String? bar;
    String? ben;
    final br = json['branch'];
    if (br is Map) {
      final bm = Map<String, dynamic>.from(br);
      bar = bm['name_ar']?.toString();
      ben = bm['name_en']?.toString();
    }

    final refs = <BookingTicketRef>[];
    final tickets = json['tickets'];
    if (tickets is List) {
      for (final e in tickets) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        Map<String, dynamic>? tmeta;
        final tm = m['metadata'];
        if (tm is Map) {
          tmeta = Map<String, dynamic>.from(tm);
        }
        final tid = m['id']?.toString() ?? '';
        if (tid.isEmpty) continue;
        refs.add(
          BookingTicketRef(
            id: tid,
            status: m['status']?.toString() ?? 'valid',
            metadata: tmeta,
          ),
        );
      }
    }

    return BookingModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      startTime: asDate(json['startTime']),
      durationHours: asInt(json['durationHours']),
      persons: asInt(json['persons']),
      totalPrice: asDouble(json['totalPrice']),
      status: json['status']?.toString() ?? '',
      couponCode: json['couponCode'] as String?,
      discountAmount: json['discountAmount'] != null
          ? asDouble(json['discountAmount'])
          : null,
      specialRequests: json['specialRequests'] as String?,
      contactPhone: json['contactPhone'] as String?,
      cancelledAt: asDateOrNull(json['cancelledAt']),
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: asDate(json['createdAt']),
      updatedAt: asDate(json['updatedAt']),
      metadata: meta,
      branchNameAr: bar,
      branchNameEn: ben,
      ticketRefs: refs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'branchId': branchId,
      'startTime': startTime.toIso8601String(),
      'durationHours': durationHours,
      'persons': persons,
      'totalPrice': totalPrice,
      'status': status,
      'couponCode': couponCode,
      'discountAmount': discountAmount,
      'specialRequests': specialRequests,
      'contactPhone': contactPhone,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      if (branchNameAr != null) 'branchNameAr': branchNameAr,
      if (branchNameEn != null) 'branchNameEn': branchNameEn,
      'ticketRefs': ticketRefs
          .map(
            (t) => {
              'id': t.id,
              'status': t.status,
              if (t.metadata != null) 'metadata': t.metadata,
            },
          )
          .toList(),
    };
  }
}
