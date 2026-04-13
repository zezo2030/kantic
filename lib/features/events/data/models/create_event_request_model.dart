// Create Event Request Model - Data Layer
class CreateEventRequestModel {
  final String type;
  final String branchId;
  final String? hallId;
  final String startTime;
  final int durationHours;
  final int persons;
  final bool decorated;
  final List<Map<String, dynamic>>? addOns;
  final String? notes;

  CreateEventRequestModel({
    required this.type,
    required this.branchId,
    this.hallId,
    required this.startTime,
    required this.durationHours,
    required this.persons,
    this.decorated = false,
    this.addOns,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      // Ensure branchId is sent (compatibility with halls)
      'branchId': branchId.isNotEmpty ? branchId : (hallId ?? ''),
      if (hallId != null) 'hallId': hallId,
      'startTime': startTime,
      'durationHours': durationHours,
      'persons': persons,
      'decorated': decorated,
      if (addOns != null) 'addOns': addOns,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

