// Event Request Repository Implementation - Data Layer
import '../../domain/entities/event_request_entity.dart';
import '../../domain/repositories/event_request_repository.dart';
import '../datasources/event_request_remote_datasource.dart';
import '../models/create_event_request_model.dart';

class EventRequestRepositoryImpl implements EventRequestRepository {
  final EventRequestRemoteDataSource remoteDataSource;

  EventRequestRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<EventRequestEntity>> getRequests({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
  }) async {
    try {
      final requests = await remoteDataSource.getRequests(
        page: page,
        limit: limit,
        status: status,
        type: type,
      );
      return requests;
    } catch (e) {
      rethrow;
    }
  }

  @override
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
  }) async {
    try {
      final dateStr =
          '${startTime.year.toString().padLeft(4, '0')}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
      final request = CreateEventRequestModel(
        type: type,
        branchId: branchId,
        hallId: hallId,
        startTime: dateStr,
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

      final eventRequestModel = await remoteDataSource.createRequest(request);
      return eventRequestModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getEventConfig({
    String? branchId,
    String? date,
  }) async {
    try {
      return await remoteDataSource.getEventConfig(
        branchId: branchId,
        date: date,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<EventRequestEntity> getRequest(String id) async {
    try {
      final request = await remoteDataSource.getRequest(id);
      return request;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEventTickets(String eventRequestId) async {
    try {
      return await remoteDataSource.getEventTickets(eventRequestId);
    } catch (e) {
      rethrow;
    }
  }
}

