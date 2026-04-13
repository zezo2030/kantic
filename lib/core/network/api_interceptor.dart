import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../constants/api_constants.dart';

class ApiInterceptor extends Interceptor {
  final SecureStorageService _storageService = SecureStorageService();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add authorization header if token exists
    final token = await _storageService.getAccessToken();
    if (token != null) {
      options.headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix}$token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 errors - token expired
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken != null) {
        try {
          // Attempt to refresh token
          final response = await Dio().post(
            '${ApiConstants.baseUrl}${ApiConstants.refreshTokenEndpoint}',
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200) {
            final dynamic responseData = response.data;
            final Map<String, dynamic> json =
                responseData is Map<String, dynamic>
                ? (responseData['data'] is Map<String, dynamic>
                      ? responseData['data'] as Map<String, dynamic>
                      : responseData)
                : <String, dynamic>{};
            final newAccessToken = json['accessToken'];
            final newRefreshToken = json['refreshToken'];

            // Save new tokens
            await _storageService.saveTokens(newAccessToken, newRefreshToken);

            // Retry original request with new token
            final options = err.requestOptions;
            options.headers[ApiConstants.authorizationHeader] =
                '${ApiConstants.bearerPrefix}$newAccessToken';

            final dio = Dio();
            final retryResponse = await dio.fetch(options);
            handler.resolve(retryResponse);
            return;
          }
        } catch (e) {
          // Refresh failed, clear tokens and redirect to login
          await _storageService.clearTokens();
        }
      }
    }

    super.onError(err, handler);
  }
}
