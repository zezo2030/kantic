import '../../domain/entities/school_trip_request_entity.dart';
import '../../domain/entities/trip_request_status.dart';
import 'trip_addon_model.dart';
import 'trip_participant_model.dart';

class SchoolTripRequestModel extends SchoolTripRequestEntity {
  const SchoolTripRequestModel({
    required super.id,
    required super.requesterId,
    super.branchId,
    required super.schoolName,
    required super.studentsCount,
    required super.accompanyingAdults,
    required super.preferredDate,
    required super.preferredTime,
    required super.durationHours,
    required super.status,
    required super.contactPersonName,
    required super.contactPhone,
    required super.contactEmail,
    required super.specialRequirements,
    required super.participants,
    required super.addOns,
    super.pricePerStudent,
    super.ticketsTotal,
    super.addOnsTotal,
    super.totalPrice,
    super.depositAmount,
    super.remainingAmount,
    super.amountPaid,
    super.paymentOption,
    required super.excelFilePath,
    required super.quotedPrice,
    required super.invoiceId,
    required super.approvedAt,
    required super.approvedBy,
    required super.rejectionReason,
    required super.adminNotes,
    required super.paymentMethod,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SchoolTripRequestModel.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['studentsList'] as List<dynamic>? ?? [];
    final addOnsJson = json['addOns'] as List<dynamic>? ?? [];

    return SchoolTripRequestModel(
      id: json['id'] as String? ?? '',
      requesterId: json['requesterId'] as String? ?? '',
      branchId: json['branchId'] as String?,
      schoolName: json['schoolName'] as String? ?? '',
      studentsCount: _asInt(json['studentsCount']),
      accompanyingAdults: _asInt(json['accompanyingAdults']),
      preferredDate: _asDate(json['preferredDate']),
      preferredTime: json['preferredTime'] as String?,
      durationHours: _asInt(json['durationHours'], fallback: 2),
      status: TripRequestStatus.fromApi(json['status'] as String?),
      contactPersonName: json['contactPersonName'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      contactEmail: json['contactEmail'] as String?,
      specialRequirements: json['specialRequirements'] as String?,
      participants: participantsJson
          .whereType<Map<String, dynamic>>()
          .map(TripParticipantModel.fromJson)
          .toList(),
      addOns: addOnsJson
          .whereType<Map<String, dynamic>>()
          .map(TripAddOnModel.fromJson)
          .toList(),
      pricePerStudent:
          _asDouble(json['pricePerStudent'] ?? json['ticketPrice']),
      ticketsTotal:
          _asDouble(json['ticketsTotal'] ?? json['ticketTotal'] ?? json['ticketsPrice']),
      addOnsTotal:
          _asDouble(json['addOnsTotal'] ?? json['addonsTotal'] ?? json['extrasTotal']),
      totalPrice:
          _asDouble(json['totalPrice'] ?? json['totalAmount'] ?? json['grandTotal']),
      depositAmount:
          _asDouble(json['depositAmount'] ?? json['downPaymentAmount']),
      remainingAmount: _asDouble(json['remainingAmount']),
      amountPaid: _asDouble(json['amountPaid']),
      paymentOption: json['paymentOption'] as String?,
      excelFilePath: json['excelFilePath'] as String?,
      quotedPrice: _asDouble(json['quotedPrice']),
      invoiceId: json['invoiceId'] as String?,
      approvedAt: _asDateOrNull(json['approvedAt']),
      approvedBy: json['approvedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      adminNotes: json['adminNotes'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'branchId': branchId,
      'schoolName': schoolName,
      'studentsCount': studentsCount,
      'accompanyingAdults': accompanyingAdults,
      'preferredDate': preferredDate.toIso8601String(),
      'preferredTime': preferredTime,
      'durationHours': durationHours,
      'status': _statusToBackend(status),
      'contactPersonName': contactPersonName,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'specialRequirements': specialRequirements,
      'studentsList': participants
          .map((participant) => participant is TripParticipantModel
              ? participant.toJson()
              : TripParticipantModel.fromEntity(participant).toJson())
          .toList(),
      'addOns': addOns
          .map((addon) => addon is TripAddOnModel
              ? addon.toJson()
              : TripAddOnModel.fromEntity(addon).toJson())
          .toList(),
      'pricePerStudent': pricePerStudent,
      'ticketsTotal': ticketsTotal,
      'addOnsTotal': addOnsTotal,
      'totalPrice': totalPrice,
      'depositAmount': depositAmount,
      'remainingAmount': remainingAmount,
      'amountPaid': amountPaid,
      'paymentOption': paymentOption,
      'excelFilePath': excelFilePath,
      'quotedPrice': quotedPrice,
      'invoiceId': invoiceId,
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'adminNotes': adminNotes,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static DateTime _asDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static DateTime? _asDateOrNull(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String _statusToBackend(TripRequestStatus status) => status.apiValue;
}

