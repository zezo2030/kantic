import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';
import '../../domain/entities/wallet_transaction_entity.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWalletBalance();
  Future<List<WalletTransactionModel>> getTransactions({
    WalletTransactionType? type,
    WalletTransactionStatus? status,
    int page = 1,
    int pageSize = 20,
  });
  Future<Map<String, dynamic>> rechargeWallet({
    required double amount,
  });

  Future<bool> confirmRechargePayment({
    required String paymentId,
    required String moyasarPaymentId,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final Dio dio;
  static const String _walletRechargeMethod = 'credit_card';

  WalletRemoteDataSourceImpl({required this.dio});

  @override
  Future<WalletModel> getWalletBalance() async {
    try {
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.walletBalanceEndpoint}',
      );

      if (response.data == null) {
        throw Exception('Wallet balance response data is null');
      }

      return WalletModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<List<WalletTransactionModel>> getTransactions({
    WalletTransactionType? type,
    WalletTransactionStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

      if (type != null) {
        queryParams['type'] = type == WalletTransactionType.deposit ? 'deposit' : 'withdrawal';
      }

      if (status != null) {
        queryParams['status'] = status == WalletTransactionStatus.success ? 'success' : 'failed';
      }

      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.walletTransactionsEndpoint}',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        throw Exception('Transactions response data is null');
      }

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      return items
          .map((item) => WalletTransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> rechargeWallet({
    required double amount,
  }) async {
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.walletRechargeEndpoint}',
        // Backend requires `method` and wallet recharge should use Moyasar card flow.
        data: {'amount': amount, 'method': _walletRechargeMethod},
      );

      if (response.data == null) {
        throw Exception('Recharge wallet response data is null');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  @override
  Future<bool> confirmRechargePayment({
    required String paymentId,
    required String moyasarPaymentId,
  }) async {
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}/payments/confirm',
        data: {
          'paymentId': paymentId,
          'gatewayPayload': {
            'moyasarPaymentId': moyasarPaymentId,
            'paymentId': moyasarPaymentId,
          },
        },
      );

      if (response.data == null) {
        throw Exception('Confirm recharge response data is null');
      }

      final data = response.data as Map<String, dynamic>;
      final directSuccess = data['success'] == true;
      final wrappedSuccess =
          data['data'] is Map<String, dynamic> && data['data']['success'] == true;
      return directSuccess || wrappedSuccess;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Unexpected error: $e');
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
            return Exception('غير مسموح لك بهذا الإجراء.');
          case 404:
            return Exception('المحفظة غير موجودة.');
          case 500:
            return Exception('خطأ في السيرفر. يرجى المحاولة لاحقاً.');
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
