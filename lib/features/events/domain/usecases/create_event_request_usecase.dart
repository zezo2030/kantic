// Create Event Request UseCase - Domain Layer
import '../entities/event_request_entity.dart';
import '../repositories/event_request_repository.dart';

class CreateEventRequestUseCase {
  final EventRequestRepository repository;

  CreateEventRequestUseCase({required this.repository});

  Future<EventRequestEntity> call({
    required String type,
    required String branchId,
    String? hallId,
    required DateTime startTime,
    required int durationHours,
    required int persons,
    bool decorated = false,
    List<Map<String, dynamic>>? addOns,
    String? notes,
    required String selectedTimeSlot,
    required bool acceptedTerms,
    required String paymentOption,
    String? paymentMethod,
  }) async {
    return await repository.createRequest(
      type: type,
      branchId: branchId,
      hallId: hallId,
      startTime: startTime,
      durationHours: durationHours,
      persons: persons,
      decorated: decorated,
      addOns: addOns,
      notes: notes,
      selectedTimeSlot: selectedTimeSlot,
      acceptedTerms: acceptedTerms,
      paymentOption: paymentOption,
      paymentMethod: paymentMethod,
    );
  }
}

