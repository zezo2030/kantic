import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart' as core show ApiConstants;
import '../../../core/network/dio_client.dart';
import '../../booking/data/models/booking_model.dart';
import '../domain/booking_status.dart';

class BookingsApi {
  final Dio _dio;

  BookingsApi({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<({List<BookingModel> items, bool hasMore, int nextPage})> fetch({
    BookingStatusFilter filter = BookingStatusFilter.all,
    int page = 1,
    int pageSize = 20,
  }) async {
    // Backend expects `page` and `limit`
    final params = <String, dynamic>{'page': page, 'limit': pageSize};
    final status = filter.apiValue;
    if (status != null) params['status'] = status;

    final response = await _dio.get(
      '${core.ApiConstants.baseUrl}/bookings',
      queryParameters: params,
    );

    final dynamic responseData = response.data;
    final Map<String, dynamic> raw = responseData is Map<String, dynamic>
        ? (responseData['data'] is Map<String, dynamic>
              ? responseData['data'] as Map<String, dynamic>
              : responseData)
        : <String, dynamic>{};

    // Backend returns { bookings, total, page, totalPages }
    final list = (raw['bookings'] ?? const <dynamic>[]) as List;
    final items = list
        .cast<dynamic>()
        .map((e) => BookingModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final int? total = raw['total'] is int ? raw['total'] as int : null;
    final bool hasMore = total != null
        ? (page * pageSize) < total
        : (list.length == pageSize);

    return (items: items, hasMore: hasMore, nextPage: page + 1);
  }

  Future<BookingModel> getBookingById(String id) async {
    final response = await _dio.get(
      '${core.ApiConstants.baseUrl}/bookings/$id',
    );

    final dynamic responseData = response.data;
    final Map<String, dynamic> raw = responseData is Map<String, dynamic>
        ? (responseData['data'] is Map<String, dynamic>
              ? responseData['data'] as Map<String, dynamic>
              : responseData)
        : <String, dynamic>{};

    return BookingModel.fromJson(raw);
  }

  Future<void> cancelBooking({required String id, String? reason}) async {
    await _dio.post(
      '${core.ApiConstants.baseUrl}/bookings/$id/cancel',
      data: reason != null && reason.isNotEmpty ? {'reason': reason} : null,
    );
  }
}
