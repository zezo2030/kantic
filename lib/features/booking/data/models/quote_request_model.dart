// Quote Request Model - Data Layer
class QuoteRequestModel {
  final String branchId;
  final String startTime;
  final int durationHours;
  final int persons;
  final List<Map<String, dynamic>>? addOns;
  final String? couponCode;

  QuoteRequestModel({
    required this.branchId,
    required this.startTime,
    required this.durationHours,
    required this.persons,
    this.addOns,
    this.couponCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'startTime': startTime,
      'durationHours': durationHours,
      'persons': persons,
      'addOns': addOns,
      'couponCode': couponCode,
    };
  }
}
