// Create Event Request Model - Data Layer
class CreateEventRequestModel {
  final String type;
  final String branchId;
  final String? hallId;
  /// Calendar date YYYY-MM-DD (backend normalizes with selectedTimeSlot).
  final String startTime;
  final int durationHours;
  final int persons;
  final bool decorated;
  final List<Map<String, dynamic>>? addOns;
  final String? notes;
  final String selectedTimeSlot;
  final bool acceptedTerms;
  final String paymentOption;
  final String? paymentMethod;

  const CreateEventRequestModel({
    required this.type,
    required this.branchId,
    this.hallId,
    required this.startTime,
    required this.durationHours,
    required this.persons,
    this.decorated = false,
    this.addOns,
    this.notes,
    required this.selectedTimeSlot,
    required this.acceptedTerms,
    required this.paymentOption,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'branchId': branchId.isNotEmpty ? branchId : (hallId ?? ''),
      if (hallId != null) 'hallId': hallId,
      'startTime': startTime,
      'durationHours': durationHours,
      'persons': persons,
      'decorated': decorated,
      if (addOns != null) 'addOns': addOns,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'selectedTimeSlot': selectedTimeSlot,
      'acceptedTerms': acceptedTerms,
      'paymentOption': paymentOption,
      if (paymentMethod != null && paymentMethod!.isNotEmpty)
        'paymentMethod': paymentMethod,
    };
  }
}
