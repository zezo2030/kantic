// Event Request Repository Interface - Domain Layer
import '../entities/event_request_entity.dart';

abstract class EventRequestRepository {
  Future<List<EventRequestEntity>> getRequests({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
  });

  Future<EventRequestEntity> createRequest({
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
  });

  /// GET /events/config — pricing, terms, add-ons, slot availability.
  Future<Map<String, dynamic>> getEventConfig({
    String? branchId,
    String? date,
  });

  Future<EventRequestEntity> getRequest(String id);
  
  Future<List<Map<String, dynamic>>> getEventTickets(String eventRequestId);
}

