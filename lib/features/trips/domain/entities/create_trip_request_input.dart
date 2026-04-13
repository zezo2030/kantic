import 'trip_addon_entity.dart';

class CreateTripRequestInput {
  final String? branchId;
  final String schoolName;
  final int? studentsCount; // Optional, will be set from Excel file
  final int? accompanyingAdults;
  final DateTime preferredDate;
  final String? preferredTime;
  final int? durationHours;
  final String contactPersonName;
  final String contactPhone;
  final String? contactEmail;
  final String? specialRequirements;
  final List<TripAddOnEntity>? addOns;
  final String? paymentMethod;

  const CreateTripRequestInput({
    this.branchId,
    required this.schoolName,
    this.studentsCount,
    this.accompanyingAdults,
    required this.preferredDate,
    this.preferredTime,
    this.durationHours,
    required this.contactPersonName,
    required this.contactPhone,
    this.contactEmail,
    this.specialRequirements,
    this.addOns,
    this.paymentMethod,
  });
}

