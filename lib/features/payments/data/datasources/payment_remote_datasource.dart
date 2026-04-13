import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/payment_models.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentIntentResponseModel> createPaymentIntent(
    CreatePaymentIntentRequestModel request,
  );

  Future<ConfirmPaymentResponseModel> confirmPayment(
    ConfirmPaymentRequestModel request,
  );
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio dio;

  PaymentRemoteDataSourceImpl({required this.dio});

  @override
  Future<PaymentIntentResponseModel> createPaymentIntent(
    CreatePaymentIntentRequestModel request,
  ) async {
    try {
      final payload = request.toJson();
      final response = await dio.post(
        '${ApiConstants.baseUrl}/payments/intent',
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      );
      if (response.data == null) {
        throw Exception('Payment intent response is null');
      }
      return PaymentIntentResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Create intent failed: ${e.message}');
    }
  }

  @override
  Future<ConfirmPaymentResponseModel> confirmPayment(
    ConfirmPaymentRequestModel request,
  ) async {
    try {
      // استخدام timeout أطول لطلبات تأكيد الدفع
      // لأن الباك إند قد يحتاج للتحقق من Tap Payments API
      final response = await dio.post(
        '${ApiConstants.baseUrl}/payments/confirm',
        data: request.toJson(),
        options: Options(
          contentType: Headers.jsonContentType,
          // timeout أطول: 60 ثانية للاتصال و 90 ثانية للاستقبال
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      if (response.data == null) {
        throw Exception('Confirm payment response is null');
      }
      return ConfirmPaymentResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      // معالجة أفضل للأخطاء
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى أو التحقق من حالة الدفع يدوياً.',
        );
      }
      throw Exception('Confirm payment failed: ${e.message}');
    }
  }
}
