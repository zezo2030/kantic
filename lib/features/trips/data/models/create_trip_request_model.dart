import '../../domain/entities/create_trip_request_input.dart';
import 'trip_addon_model.dart';

class CreateTripRequestModel {
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
  final List<TripAddOnModel>? addOns;
  final String? paymentMethod;

  const CreateTripRequestModel({
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

  factory CreateTripRequestModel.fromInput(CreateTripRequestInput input) {
    return CreateTripRequestModel(
      branchId: input.branchId,
      schoolName: input.schoolName,
      studentsCount: input.studentsCount,
      accompanyingAdults: input.accompanyingAdults,
      preferredDate: input.preferredDate,
      preferredTime: input.preferredTime,
      durationHours: input.durationHours,
      contactPersonName: input.contactPersonName,
      contactPhone: input.contactPhone,
      contactEmail: input.contactEmail,
      specialRequirements: input.specialRequirements,
      addOns:
          input.addOns?.map((addon) => TripAddOnModel.fromEntity(addon)).toList(),
      paymentMethod: input.paymentMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (branchId != null) 'branchId': branchId,
      'schoolName': schoolName,
      if (studentsCount != null && studentsCount! > 0) 'studentsCount': studentsCount,
      if (accompanyingAdults != null) 'accompanyingAdults': accompanyingAdults,
      'preferredDate': preferredDate.toIso8601String(),
      if (preferredTime != null) 'preferredTime': preferredTime,
      if (durationHours != null) 'durationHours': durationHours,
      'contactPersonName': contactPersonName,
      'contactPhone': contactPhone,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (specialRequirements != null)
        'specialRequirements': specialRequirements,
      if (addOns != null)
        'addOns': addOns!.map((addon) => addon.toJson()).toList(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    };
  }
}

