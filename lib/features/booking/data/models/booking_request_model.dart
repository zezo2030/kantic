// Booking Request Model - Data Layer
class BookingRequestModel {
  final String branchId;
  final String startTime;
  final int durationHours;
  final int persons;
  final String? couponCode;
  final List<Map<String, dynamic>>? addOns;
  final String? specialRequests;
  final String? contactPhone;

  BookingRequestModel({
    required this.branchId,
    required this.startTime,
    required this.durationHours,
    required this.persons,
    this.couponCode,
    this.addOns,
    this.specialRequests,
    this.contactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'startTime': startTime,
      'durationHours': durationHours,
      'persons': persons,
      'couponCode': couponCode,
      'addOns': addOns,
      'specialRequests': specialRequests,
      'contactPhone': contactPhone,
    };
  }
}
