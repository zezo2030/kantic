import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/api_json.dart';

abstract class OfferProductsRemoteDataSource {
  Future<Map<String, dynamic>> fetchByBranch(String branchId);
  Future<Map<String, dynamic>> quote({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
  });
  Future<Map<String, dynamic>> createBooking({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
    String? contactPhone,
    required bool acceptedTerms,
  });
  Future<Map<String, dynamic>> fetchMyBookings({int page = 1, int limit = 10});
  Future<Map<String, dynamic>> fetchBookingDetails(String id);
  Future<Map<String, dynamic>> fetchBookingTickets(String bookingId);
}

class OfferProductsRemoteDataSourceImpl
    implements OfferProductsRemoteDataSource {
  final Dio dio;

  OfferProductsRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> fetchByBranch(String branchId) async {
    final res = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.branchOfferProducts(branchId)}',
    );
    return unwrapData(res.data);
  }

  @override
  Future<Map<String, dynamic>> quote({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
  }) async {
    final res = await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.offerQuoteEndpoint}',
      data: {
        'offerProductId': offerProductId,
        if (addOns != null && addOns.isNotEmpty) 'addOns': addOns,
      },
    );
    return unwrapData(res.data);
  }

  @override
  Future<Map<String, dynamic>> createBooking({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
    String? contactPhone,
    required bool acceptedTerms,
  }) async {
    final res = await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.offerBookingsEndpoint}',
      data: {
        'offerProductId': offerProductId,
        'acceptedTerms': acceptedTerms,
        if (addOns != null && addOns.isNotEmpty) 'addOns': addOns,
        if (contactPhone != null && contactPhone.isNotEmpty)
          'contactPhone': contactPhone,
      },
    );
    return unwrapData(res.data);
  }

  @override
  Future<Map<String, dynamic>> fetchMyBookings({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.offerBookingsEndpoint}',
      queryParameters: {'page': page, 'limit': limit},
    );
    return unwrapData(res.data);
  }

  @override
  Future<Map<String, dynamic>> fetchBookingDetails(String id) async {
    final res = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.offerBookingDetails(id)}',
    );
    return unwrapData(res.data);
  }

  @override
  Future<Map<String, dynamic>> fetchBookingTickets(String bookingId) async {
    final res = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.offerBookingTickets(bookingId)}',
    );
    return unwrapData(res.data);
  }
}
