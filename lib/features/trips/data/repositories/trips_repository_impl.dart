import 'package:dio/dio.dart';

import '../../domain/entities/create_trip_request_input.dart';
import '../../domain/entities/school_trip_request_entity.dart';
import '../../domain/entities/submit_trip_request_input.dart';
import '../../domain/entities/trip_participants_upload_entity.dart';
import '../../domain/entities/trip_requests_filter.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/trips_remote_datasource.dart';
import '../models/create_trip_request_model.dart';
import '../models/submit_trip_request_model.dart';

class TripsRepositoryImpl implements TripsRepository {
  final TripsRemoteDataSource remoteDataSource;

  const TripsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> createTripRequest(CreateTripRequestInput input) async {
    try {
      final requestModel = CreateTripRequestModel.fromInput(input);
      return await remoteDataSource.createTripRequest(requestModel);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('فشل إنشاء طلب الرحلة: $e');
    }
  }

  @override
  Future<SchoolTripRequestEntity> getTripRequest(String requestId) async {
    try {
      return await remoteDataSource.getTripRequest(requestId);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('فشل جلب تفاصيل طلب الرحلة: $e');
    }
  }

  @override
  Future<List<SchoolTripRequestEntity>> getTripRequests(
    TripRequestsFilter filter,
  ) async {
    try {
      return await remoteDataSource.getMyTripRequests(
        page: filter.page,
        limit: filter.limit,
        status: filter.status?.apiValue,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('تعذر تحميل قائمة طلبات الرحلات: $e');
    }
  }

  @override
  Future<void> submitTripRequest({
    required String requestId,
    required SubmitTripRequestInput input,
  }) async {
    try {
      final payload = SubmitTripRequestModel.fromInput(input);
      await remoteDataSource.submitTripRequest(
        requestId: requestId,
        payload: payload,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('تعذر إرسال الطلب للمراجعة: $e');
    }
  }

  @override
  Future<int> uploadParticipants({
    required String requestId,
    required TripParticipantsUploadEntity upload,
  }) async {
    try {
      final file = MultipartFile.fromBytes(
        upload.bytes,
        filename: upload.filename,
      );
      return await remoteDataSource.uploadParticipants(
        requestId: requestId,
        file: file,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('تعذر رفع ملف الطلاب: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTripTickets(
    String tripRequestId,
  ) async {
    try {
      return await remoteDataSource.getTripTickets(tripRequestId);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('تعذر جلب تذاكر الرحلة: $e');
    }
  }

  @override
  Future<void> cancelTripRequest({
    required String requestId,
    String? reason,
  }) async {
    try {
      await remoteDataSource.cancelTripRequest(
        requestId: requestId,
        reason: reason,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('تعذر إلغاء طلب الرحلة: $e');
    }
  }

  @override
  Future<SchoolTripRequestEntity> updateTripRequest({
    required String requestId,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await remoteDataSource.updateTripRequest(
        requestId: requestId,
        data: data,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('تعذر تحديث طلب الرحلة: $e');
    }
  }

  Exception _handleDioException(DioException error) {
    final status = error.response?.statusCode;
    final message = error.response?.data is Map<String, dynamic>
        ? (error.response!.data['message'] as String?)
        : null;

    switch (status) {
      case 400:
        return Exception(
          message ?? 'البيانات غير صحيحة، يرجى التحقق والمحاولة.',
        );
      case 401:
      case 403:
        return Exception('يرجى تسجيل الدخول للوصول إلى هذه الميزة.');
      case 404:
        return Exception('لم يتم العثور على طلب الرحلة.');
      case 409:
        return Exception(message ?? 'يوجد تعارض في حالة الطلب الحالية.');
      case 500:
        return Exception('حدث خطأ في الخادم، حاول لاحقاً.');
      default:
        return Exception(message ?? 'خطأ غير متوقع: ${error.message}');
    }
  }
}
