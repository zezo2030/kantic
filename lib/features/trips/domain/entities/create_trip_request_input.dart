import 'trip_addon_entity.dart';

class CreateTripRequestInput {
  final String? branchId;
  final String schoolName;
  /// Headcount sent to API (branch minimum from `/trips/config`).
  final int studentsCount;
  final DateTime preferredDate;
  final String? preferredTime;
  final int? durationHours;
  final String? specialRequirements;
  final List<TripAddOnEntity>? addOns;
  final String? paymentMethod;
  /// `full` or `deposit` (required by API).
  final String paymentOption;

  const CreateTripRequestInput({
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
}
