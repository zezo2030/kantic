// Booking Remote DataSource - Data Layer
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/booking_model.dart';
import '../models/booking_request_model.dart';
import '../models/quote_model.dart';
import '../models/quote_request_model.dart';
import '../models/hall_slots_model.dart'; // Contains BranchSlotsModel

abstract class BookingRemoteDataSource {
  Future<BookingModel> createBooking(BookingRequestModel request);
  Future<QuoteModel> getQuote(QuoteRequestModel request);
  Future<BranchSlotsModel> getBranchSlots({
    required String branchId,
    required String date,
    required int durationHours,
    int? slotMinutes,
    int? persons,
  });
  Future<bool> checkAvailability(
    String branchId,
    String startTime,
    int durationHours,
  );
  Future<bool> checkServerHealth();
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final Dio dio;

  BookingRemoteDataSourceImpl({required this.dio});

  @override
  Future<BookingModel> createBooking(BookingRequestModel request) async {
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}/bookings',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw Exception('Booking response data is null');
      }

      return BookingModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<QuoteModel> getQuote(QuoteRequestModel request) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final response = await dio.post(
          '${ApiConstants.baseUrl}/bookings/quote',
          data: request.toJson(),
        );

        if (response.data == null) {
          throw Exception('Quote response data is null');
        }

        return QuoteModel.fromJson(response.data);
      } on DioException catch (e) {
        retryCount++;

        // إذا كان الخطأ 500 أو مشكلة في الشبكة، نحاول مرة أخرى
        if (e.response?.statusCode == 500 ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          if (retryCount >= maxRetries) {
            throw _handleDioException(e);
          }

          // انتظار قبل المحاولة مرة أخرى (exponential backoff)
          final delaySeconds = retryCount * 2;
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        } else {
          // للأخطاء الأخرى، لا نحاول مرة أخرى
          throw _handleDioException(e);
        }
      } catch (e) {
        throw Exception('خطأ غير متوقع: $e');
      }
    }

    throw Exception('فشل في الحصول على عرض السعر بعد $maxRetries محاولات');
  }

  @override
  Future<BranchSlotsModel> getBranchSlots({
    required String branchId,
    required String date,
    required int durationHours,
    int? slotMinutes,
    int? persons,
  }) async {
    try {
      final response = await dio.get(
        '${ApiConstants.baseUrl}/content/branches/$branchId/slots',
        queryParameters: {
          'date': date,
          'durationHours': durationHours,
          if (slotMinutes != null) 'slotMinutes': slotMinutes,
          if (persons != null) 'persons': persons,
        },
      );

      if (response.data == null) {
        throw Exception('Slots response data is null');
      }

      return BranchSlotsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<bool> checkAvailability(
    String branchId,
    String startTime,
    int durationHours,
  ) async {
    try {
      final response = await dio.get(
        '${ApiConstants.baseUrl}/content/branches/$branchId/availability',
        queryParameters: {
          'startTime': startTime,
          'durationHours': durationHours,
        },
      );

      if (response.data == null) {
        throw Exception('Availability response data is null');
      }

      return response.data['available'] as bool;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<bool> checkServerHealth() async {
    try {
      final response = await dio.get('${ApiConstants.baseUrl}/health');
      final isHealthy = response.statusCode == 200;
      return isHealthy;
    } catch (e) {
      return false;
    }
  }

  Exception _handleDioException(DioException e) {

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        switch (statusCode) {
          case 400:
            // التحقق من رسالة الخطأ المحددة
            final message = responseData is Map<String, dynamic> 
                ? responseData['message'] as String? 
                : null;
            
            if (message != null && message.contains('pricing configuration')) {
              return Exception(
                'الفرع لا يحتوي على إعدادات التسعير. يرجى التواصل مع الدعم الفني.',
              );
            }
            
            return Exception(
              'طلب غير صحيح. يرجى التحقق من بيانات الحجز المرسلة.',
            );
          case 401:
            return Exception(
              'غير مصرح لك بالوصول. يرجى تسجيل الدخول مرة أخرى.',
            );
          case 403:
            return Exception('غير مسموح لك بإنشاء حجوزات.');
          case 404:
            return Exception('الفرع غير موجود.');
          case 409:
            return Exception('الفرع غير متاح في الوقت المحدد.');
          case 500:
            return Exception(
              'خطأ في السيرفر. يرجى المحاولة لاحقاً أو التواصل مع الدعم الفني.',
            );
          default:
            return Exception('خطأ في السيرفر برمز الحالة: $statusCode');
        }
      case DioExceptionType.cancel:
        return Exception('تم إلغاء الطلب.');
      case DioExceptionType.connectionError:
        return Exception('لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.');
      default:
        return Exception('خطأ في الشبكة: ${e.message}');
    }
  }
}
