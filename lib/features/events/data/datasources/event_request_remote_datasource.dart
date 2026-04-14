// Event Request Remote DataSource - Data Layer
import '../models/event_request_model.dart';
import '../models/create_event_request_model.dart';
import '../event_requests_api.dart';

abstract class EventRequestRemoteDataSource {
  Future<List<EventRequestModel>> getRequests({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
  });
  Future<EventRequestModel> createRequest(CreateEventRequestModel request);
  Future<Map<String, dynamic>> getEventConfig({
    String? branchId,
    String? date,
  });
  Future<EventRequestModel> getRequest(String id);
  Future<List<Map<String, dynamic>>> getEventTickets(String eventRequestId);
}

class EventRequestRemoteDataSourceImpl implements EventRequestRemoteDataSource {
  final EventRequestsApi api;

  EventRequestRemoteDataSourceImpl({required this.api});

  @override
  Future<List<EventRequestModel>> getRequests({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
  }) async {
    try {
      final result = await api.fetch(
        page: page,
        limit: limit,
        status: status,
        type: type,
      );
      // Return the requests list
      return result.requests;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<EventRequestModel> createRequest(CreateEventRequestModel request) async {
    try {
      return await api.create(request);
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
      return await api.fetchConfig(branchId: branchId, date: date);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<EventRequestModel> getRequest(String id) async {
    try {
      return await api.getById(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEventTickets(String eventRequestId) async {
    try {
      return await api.getEventTickets(eventRequestId);
    } catch (e) {
      rethrow;
    }
  }
}

