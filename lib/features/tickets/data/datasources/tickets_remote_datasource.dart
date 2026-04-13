import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/ticket_model.dart';

abstract class TicketsRemoteDataSource {
  Future<List<TicketModel>> getBookingTickets(String bookingId);
  Future<String> getTicketQr(String ticketId);
}

class TicketsRemoteDataSourceImpl implements TicketsRemoteDataSource {
  final Dio dio;
  TicketsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<TicketModel>> getBookingTickets(String bookingId) async {
    final response = await dio.get(
      '${ApiConstants.baseUrl}/bookings/$bookingId/tickets',
    );
    final dynamic responseData = response.data;
    final dynamic raw = responseData is Map<String, dynamic>
        ? (responseData['data'] ?? responseData)
        : responseData;
    final list = (raw as List).cast<dynamic>();
    return list
        .map((e) => TicketModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<String> getTicketQr(String ticketId) async {
    final response = await dio.get(
      '${ApiConstants.baseUrl}/tickets/$ticketId/qr',
    );
    final dynamic responseData = response.data;
    final Map<String, dynamic> data = responseData is Map<String, dynamic>
        ? (responseData['data'] is Map<String, dynamic>
              ? responseData['data'] as Map<String, dynamic>
              : responseData)
        : <String, dynamic>{};
    return data['qr']?.toString() ?? data['dataUrl']?.toString() ?? '';
  }
}
