import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart' as core show ApiConstants;
import '../../../core/network/dio_client.dart';
import 'models/event_request_model.dart';
import 'models/create_event_request_model.dart';

class EventRequestsApi {
  final Dio _dio;

  EventRequestsApi({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<Map<String, dynamic>> fetchConfig({
    String? branchId,
    String? date,
  }) async {
    final params = <String, dynamic>{};
    if (branchId != null && branchId.isNotEmpty) params['branchId'] = branchId;
    if (date != null && date.isNotEmpty) params['date'] = date;

    final response = await _dio.get(
      '${core.ApiConstants.baseUrl}${core.ApiConstants.eventsConfigEndpoint}',
      queryParameters: params.isEmpty ? null : params,
    );

    final dynamic responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      final nested = responseData['data'];
      if (nested is Map<String, dynamic>) return nested;
      return responseData;
    }
    return <String, dynamic>{};
  }

  Future<({List<EventRequestModel> requests, int total, int page, int totalPages})> fetch({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) params['status'] = status;
    if (type != null) params['type'] = type;

    final response = await _dio.get(
      '${core.ApiConstants.baseUrl}${core.ApiConstants.eventsRequestsEndpoint}',
      queryParameters: params,
    );

    final dynamic responseData = response.data;
    final Map<String, dynamic> raw = responseData is Map<String, dynamic>
        ? (responseData['data'] is Map<String, dynamic>
              ? responseData['data'] as Map<String, dynamic>
              : responseData)
        : <String, dynamic>{};

    // Backend returns { requests, total, page, totalPages }
    final list = (raw['requests'] ?? const <dynamic>[]) as List;
    final requests = list
        .cast<dynamic>()
        .map((e) => EventRequestModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final int total = raw['total'] is int ? raw['total'] as int : requests.length;
    final int currentPage = raw['page'] is int ? raw['page'] as int : page;
    final int totalPages = raw['totalPages'] is int 
        ? raw['totalPages'] as int 
        : (total > 0 ? ((total - 1) ~/ limit + 1) : 1);

    return (requests: requests, total: total, page: currentPage, totalPages: totalPages);
  }

  Future<EventRequestModel> create(CreateEventRequestModel request) async {
    final response = await _dio.post(
      '${core.ApiConstants.baseUrl}${core.ApiConstants.eventsRequestsCreateEndpoint}',
      data: request.toJson(),
    );

    final dynamic responseData = response.data;
    final Map<String, dynamic> raw = responseData is Map<String, dynamic>
        ? (responseData['data'] is Map<String, dynamic>
              ? responseData['data'] as Map<String, dynamic>
              : responseData)
        : <String, dynamic>{};

    // Backend returns { id } after creation, so we need to fetch the full request
    final String id = raw['id'] as String? ?? '';
    return await getById(id);
  }

  Future<EventRequestModel> getById(String id) async {
    final response = await _dio.get(
      '${core.ApiConstants.baseUrl}${core.ApiConstants.eventsRequestDetailEndpoint(id)}',
    );

    final dynamic responseData = response.data;
    final Map<String, dynamic> raw = responseData is Map<String, dynamic>
        ? (responseData['data'] is Map<String, dynamic>
              ? responseData['data'] as Map<String, dynamic>
              : responseData)
        : <String, dynamic>{};

    return EventRequestModel.fromJson(raw);
  }

  Future<List<Map<String, dynamic>>> getEventTickets(String eventRequestId) async {
    final response = await _dio.get(
      '${core.ApiConstants.baseUrl}/events/requests/$eventRequestId/tickets',
    );

    final dynamic responseData = response.data;
    final dynamic raw = responseData is Map<String, dynamic>
        ? (responseData['data'] ?? responseData)
        : responseData;
    
    final list = (raw as List).cast<dynamic>();
    return list
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }
}

