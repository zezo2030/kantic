import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/create_trip_request_model.dart';
import '../models/school_trip_request_model.dart';
import '../models/submit_trip_request_model.dart';

abstract class TripsRemoteDataSource {
  Future<String> createTripRequest(CreateTripRequestModel request);

  Future<SchoolTripRequestModel> getTripRequest(String requestId);

  Future<List<SchoolTripRequestModel>> getMyTripRequests({
    int page,
    int limit,
    String? status,
  });

  Future<void> submitTripRequest({
    required String requestId,
    required SubmitTripRequestModel payload,
  });

  Future<int> uploadParticipants({
    required String requestId,
    required MultipartFile file,
  });

  Future<List<Map<String, dynamic>>> getTripTickets(String tripRequestId);

  Future<void> cancelTripRequest({required String requestId, String? reason});

  Future<SchoolTripRequestModel> updateTripRequest({
    required String requestId,
    required Map<String, dynamic> data,
  });
}

class TripsRemoteDataSourceImpl implements TripsRemoteDataSource {
  final Dio dio;

  TripsRemoteDataSourceImpl({required this.dio});

  @override
  Future<String> createTripRequest(CreateTripRequestModel request) async {
    final response = await dio.post(
      '${ApiConstants.baseUrl}/trips/requests',
      data: request.toJson(),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final id = data['id'] ?? data['requestId'];
      if (id is String && id.isNotEmpty) {
        return id;
      }
    }

    throw Exception('فشل إنشاء طلب الرحلة المدرسية');
  }

  @override
  Future<SchoolTripRequestModel> getTripRequest(String requestId) async {
    final response = await dio.get(
      '${ApiConstants.baseUrl}/trips/requests/$requestId',
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        return SchoolTripRequestModel.fromJson(payload);
      }
      return SchoolTripRequestModel.fromJson(data);
    }

    throw Exception('تعذر جلب تفاصيل طلب الرحلة.');
  }

  @override
  Future<List<SchoolTripRequestModel>> getMyTripRequests({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    };

    final response = await dio.get(
      '${ApiConstants.baseUrl}/trips/requests',
      queryParameters: query,
    );

    final data = response.data;

    List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      final nestedData = data['data'];
      if (nestedData is Map<String, dynamic>) {
        final requests = nestedData['requests'] ?? nestedData['items'];
        if (requests is List) {
          rawList = requests;
        } else {
          rawList = [];
        }
      } else if (data['requests'] is List) {
        rawList = data['requests'] as List<dynamic>;
      } else if (data['items'] is List) {
        rawList = data['items'] as List<dynamic>;
      } else {
        rawList = [];
      }
    } else {
      rawList = [];
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(SchoolTripRequestModel.fromJson)
        .toList();
  }

  @override
  Future<void> submitTripRequest({
    required String requestId,
    required SubmitTripRequestModel payload,
  }) async {
    await dio.post(
      '${ApiConstants.baseUrl}/trips/requests/$requestId/submit',
      data: payload.toJson(),
    );
  }

  @override
  Future<int> uploadParticipants({
    required String requestId,
    required MultipartFile file,
  }) async {
    final formData = FormData.fromMap({'file': file});

    final response = await dio.post(
      '${ApiConstants.baseUrl}/trips/requests/$requestId/upload',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final count = data['count'] ?? data['uploaded'];
      if (count is int) return count;
      if (count is num) return count.toInt();
    }

    return 0;
  }

  @override
  Future<List<Map<String, dynamic>>> getTripTickets(
    String tripRequestId,
  ) async {
    final response = await dio.get(
      '${ApiConstants.baseUrl}/trips/requests/$tripRequestId/tickets',
    );

    final dynamic responseData = response.data;
    final dynamic raw = responseData is Map<String, dynamic>
        ? (responseData['data'] ?? responseData)
        : responseData;

    final list = (raw as List).cast<dynamic>();
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  @override
  Future<void> cancelTripRequest({
    required String requestId,
    String? reason,
  }) async {
    await dio.post(
      '${ApiConstants.baseUrl}/trips/requests/$requestId/cancel',
      data: {if (reason != null) 'reason': reason},
    );
  }

  @override
  Future<SchoolTripRequestModel> updateTripRequest({
    required String requestId,
    required Map<String, dynamic> data,
  }) async {
    final response = await dio.patch(
      '${ApiConstants.baseUrl}/trips/requests/$requestId',
      data: data,
    );

    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      final payload = responseData['data'];
      if (payload is Map<String, dynamic>) {
        return SchoolTripRequestModel.fromJson(payload);
      }
      return SchoolTripRequestModel.fromJson(responseData);
    }

    throw Exception('تعذر تحديث طلب الرحلة.');
  }
}
