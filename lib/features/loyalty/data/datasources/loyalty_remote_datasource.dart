import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/loyalty_models.dart';

abstract class LoyaltyRemoteDataSource {
  Future<LoyaltyInfoModel> getLoyaltyInfo();
  Future<Map<String, dynamic>> redeemTicket({required String branchId});
}

class LoyaltyRemoteDataSourceImpl implements LoyaltyRemoteDataSource {
  final Dio dio;

  LoyaltyRemoteDataSourceImpl({required this.dio});

  @override
  Future<LoyaltyInfoModel> getLoyaltyInfo() async {
    try {
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.loyaltyMeEndpoint}',
      );
      if (response.data == null) {
        throw Exception('Loyalty info response is null');
      }
      return LoyaltyInfoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> redeemTicket({required String branchId}) async {
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.loyaltyRedeemTicketEndpoint}',
        data: {'branchId': branchId},
      );
      if (response.data == null) {
        throw Exception('Redeem ticket response is null');
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioException(e);
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
        final message = responseData is Map && responseData['message'] != null
            ? responseData['message']
            : 'خطأ في الطلب';
        switch (statusCode) {
          case 400:
            return Exception(message);
          case 401:
            return Exception('غير مصرح لك بالوصول. يرجى تسجيل الدخول مرة أخرى.');
          case 403:
            return Exception(message.toString().contains('points')
                ? 'نقاطك غير كافية لاستبدال تذكرة.'
                : 'غير مسموح لك بهذا الإجراء.');
          case 404:
            return Exception('الفرع غير موجود.');
          case 500:
            return Exception('خطأ في السيرفر. يرجى المحاولة لاحقاً.');
          default:
            return Exception('خطأ برمز الحالة: $statusCode');
        }
      case DioExceptionType.connectionError:
        return Exception('لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.');
      default:
        return Exception('خطأ في الشبكة: ${e.message}');
    }
  }
}
