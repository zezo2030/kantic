import 'package:equatable/equatable.dart';

import 'trip_addon_entity.dart';
import 'trip_participant_entity.dart';
import 'trip_request_status.dart';

class SchoolTripRequestEntity extends Equatable {
  final String id;
  final String requesterId;
  final String? branchId;
  final String schoolName;
  final int studentsCount;
  final int accompanyingAdults;
  final DateTime preferredDate;
  final String? preferredTime;
  final int durationHours;
  final TripRequestStatus status;
  final String contactPersonName;
  final String contactPhone;
  final String? contactEmail;
  final String? specialRequirements;
  final List<TripParticipantEntity> participants;
  final List<TripAddOnEntity> addOns;
  final double? pricePerStudent;
  final double? ticketsTotal;
  final double? addOnsTotal;
  final double? totalPrice;
  final double? depositAmount;
  /// After partial (deposit) payment — from API when available.
  final double? remainingAmount;
  final double? amountPaid;
  final String? paymentOption;
  final String? excelFilePath;
  final double? quotedPrice;
  final String? invoiceId;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;
  final String? adminNotes;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchoolTripRequestEntity({
    required this.id,
    required this.requesterId,
    this.branchId,
    required this.schoolName,
    required this.studentsCount,
    required this.accompanyingAdults,
    required this.preferredDate,
    required this.preferredTime,
    required this.durationHours,
    required this.status,
    required this.contactPersonName,
    required this.contactPhone,
    required this.contactEmail,
    required this.specialRequirements,
    required this.participants,
    required this.addOns,
    this.pricePerStudent,
    this.ticketsTotal,
    this.addOnsTotal,
    this.totalPrice,
    this.depositAmount,
    this.remainingAmount,
    this.amountPaid,
    this.paymentOption,
    required this.excelFilePath,
    required this.quotedPrice,
    required this.invoiceId,
    required this.approvedAt,
    required this.approvedBy,
    required this.rejectionReason,
    required this.adminNotes,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  SchoolTripRequestEntity copyWith({
    String? id,
    String? requesterId,
    String? branchId,
    String? schoolName,
    int? studentsCount,
    int? accompanyingAdults,
    DateTime? preferredDate,
    String? preferredTime,
    int? durationHours,
    TripRequestStatus? status,
    String? contactPersonName,
    String? contactPhone,
    String? contactEmail,
    String? specialRequirements,
    List<TripParticipantEntity>? participants,
    List<TripAddOnEntity>? addOns,
    double? pricePerStudent,
    double? ticketsTotal,
    double? addOnsTotal,
    double? totalPrice,
    double? depositAmount,
    double? remainingAmount,
    double? amountPaid,
    String? paymentOption,
    String? excelFilePath,
    double? quotedPrice,
    String? invoiceId,
    DateTime? approvedAt,
    String? approvedBy,
    String? rejectionReason,
    String? adminNotes,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolTripRequestEntity(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      branchId: branchId ?? this.branchId,
      schoolName: schoolName ?? this.schoolName,
      studentsCount: studentsCount ?? this.studentsCount,
      accompanyingAdults: accompanyingAdults ?? this.accompanyingAdults,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTime: preferredTime ?? this.preferredTime,
      durationHours: durationHours ?? this.durationHours,
      status: status ?? this.status,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      participants: participants ?? this.participants,
      addOns: addOns ?? this.addOns,
      pricePerStudent: pricePerStudent ?? this.pricePerStudent,
      ticketsTotal: ticketsTotal ?? this.ticketsTotal,
      addOnsTotal: addOnsTotal ?? this.addOnsTotal,
      totalPrice: totalPrice ?? this.totalPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentOption: paymentOption ?? this.paymentOption,
      excelFilePath: excelFilePath ?? this.excelFilePath,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      invoiceId: invoiceId ?? this.invoiceId,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNotes: adminNotes ?? this.adminNotes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        requesterId,
        schoolName,
        studentsCount,
        accompanyingAdults,
        preferredDate,
        preferredTime,
        durationHours,
        status,
        contactPersonName,
        contactPhone,
        contactEmail,
        specialRequirements,
        participants,
        addOns,
        pricePerStudent,
        ticketsTotal,
        addOnsTotal,
        totalPrice,
        depositAmount,
        remainingAmount,
        amountPaid,
        paymentOption,
        excelFilePath,
        quotedPrice,
        invoiceId,
        approvedAt,
        approvedBy,
        rejectionReason,
        adminNotes,
        paymentMethod,
        createdAt,
        updatedAt,
      ];
}

