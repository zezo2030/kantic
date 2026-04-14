import '../../domain/entities/create_trip_request_input.dart';
import 'trip_addon_model.dart';

class CreateTripRequestModel {
  final String? branchId;
  final String schoolName;
  final int studentsCount;
  final DateTime preferredDate;
  final String? preferredTime;
  final int? durationHours;
  final String? specialRequirements;
  final List<TripAddOnModel>? addOns;
  final String? paymentMethod;
  final String paymentOption;

  const CreateTripRequestModel({
    this.branchId,
    required this.schoolName,
    required this.studentsCount,
    required this.preferredDate,
    this.preferredTime,
    this.durationHours,
    this.specialRequirements,
    this.addOns,
    this.paymentMethod,
    this.paymentOption = 'full',
  });

  factory CreateTripRequestModel.fromInput(CreateTripRequestInput input) {
    return CreateTripRequestModel(
      branchId: input.branchId,
      schoolName: input.schoolName,
      studentsCount: input.studentsCount,
      preferredDate: input.preferredDate,
      preferredTime: input.preferredTime,
      durationHours: input.durationHours,
      specialRequirements: input.specialRequirements,
      addOns:
          input.addOns?.map((addon) => TripAddOnModel.fromEntity(addon)).toList(),
      paymentMethod: input.paymentMethod,
      paymentOption: input.paymentOption,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (branchId != null) 'branchId': branchId,
      'schoolName': schoolName,
      if (studentsCount > 0) 'studentsCount': studentsCount,
      'preferredDate': preferredDate.toIso8601String(),
      if (preferredTime != null) 'preferredTime': preferredTime,
      if (durationHours != null) 'durationHours': durationHours,
      if (specialRequirements != null)
        'specialRequirements': specialRequirements,
      if (addOns != null)
        'addOns': addOns!.map((addon) => addon.toJson()).toList(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'paymentOption': paymentOption,
    };
  }
}
