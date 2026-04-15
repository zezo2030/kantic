import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../models/update_profile_dto.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String phone,
    required String password,
  });

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String language = 'ar',
  });

  Future<bool> sendOtp({required String phone, String language = 'ar'});

  Future<AuthResponseModel> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<bool> registerSendOtp({
    required String phone,
    String language = 'ar',
  });

  Future<Map<String, dynamic>> registerVerifyOtp({
    required String phone,
    required String otp,
  });

  Future<AuthResponseModel> completeRegistration({
    required String phone,
    required String name,
    required String password,
    String language = 'ar',
  });

  Future<UserModel> getProfile();

  Future<AuthResponseModel> refreshToken({required String refreshToken});

  Future<UserModel> updateProfile(UpdateProfileDto updateProfileDto);

  Future<UserModel> refreshProfile();

  Future<bool> updateLanguage(String language);

  Future<void> deleteAccount();

  Future<bool> forgotPasswordSendOtp({
    required String phone,
    String language = 'ar',
  });

  Future<String> forgotPasswordReset({
    required String phone,
    required String otp,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  Map<String, dynamic> _normalizeAuthPayload(Map<String, dynamic> json) {
    final Map<String, dynamic> normalized = Map<String, dynamic>.from(json);

    normalized['accessToken'] =
        normalized['accessToken'] ??
        json['access_token'] ??
        json['token'] ??
        json['access'];
    normalized['refreshToken'] =
        normalized['refreshToken'] ?? json['refresh_token'] ?? json['refresh'];

    final dynamic userRaw = normalized['user'] ?? json['user'];
    if (userRaw is Map<String, dynamic>) {
      final Map<String, dynamic> userMap = Map<String, dynamic>.from(userRaw);
      // Fill safe defaults and map common alternative keys
      userMap['id'] = userMap['id'] ?? userMap['_id'] ?? '';
      userMap['email'] = userMap['email'] ?? '';
      userMap['name'] =
          userMap['name'] ??
          userMap['fullName'] ??
          userMap['username'] ??
          (userMap['email'] ?? 'User');
      userMap['language'] = userMap['language'] ?? 'ar';
      userMap['roles'] = (userMap['roles'] is List)
          ? userMap['roles']
          : <String>[];
      userMap['createdAt'] =
          userMap['createdAt'] ?? DateTime.now().toIso8601String();
      normalized['user'] = userMap;
    } else {
      // If no user data (e.g., refresh token response), create a minimal user object
      // This will be replaced by getProfile() call after token refresh
      normalized['user'] = {
        'id': '',
        'email': '',
        'name': 'User',
        'language': 'ar',
        'roles': <String>[],
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      };
    }

    return normalized;
  }

  Map<String, dynamic> _normalizeUserPayload(Map<String, dynamic> json) {
    final Map<String, dynamic> userMap = Map<String, dynamic>.from(json);
    
    // Handle nullable email - set to empty string if null
    userMap['email'] = userMap['email'] ?? '';
    
    // Handle nullable phone - keep as is (already nullable in model)
    // userMap['phone'] is already handled as nullable
    
    userMap['language'] = userMap['language'] ?? 'ar';
    userMap['roles'] = (userMap['roles'] is List)
        ? userMap['roles']
        : <String>[];
    userMap['createdAt'] =
        userMap['createdAt'] ?? DateTime.now().toIso8601String();
    return userMap;
  }

  @override
  Future<AuthResponseModel> login({
    required String phone,
    required String password,
  }) async {
    final response = await dio.post(
      ApiConstants.loginEndpoint,
      data: {'phone': phone, 'password': password},
    );

    final dynamic responseData = response.data;
    final Map<String, dynamic> json = responseData is Map<String, dynamic>
        ? (responseData['data'] is Map<String, dynamic>
              ? responseData['data'] as Map<String, dynamic>
              : responseData)
        : <String, dynamic>{};

    final normalized = _normalizeAuthPayload(json);
    return AuthResponseModel.fromJson(normalized);
  }

  @override
  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String language = 'ar',
  }) async {
    try {

      final response = await dio.post(
        ApiConstants.registerEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'language': language,
        },
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is Map<String, dynamic>
          ? (responseData['data'] is Map<String, dynamic>
                ? responseData['data'] as Map<String, dynamic>
                : responseData)
          : <String, dynamic>{};

      final normalized = _normalizeAuthPayload(json);
      return AuthResponseModel.fromJson(normalized);
    } catch (e) {
      throw Exception('Register failed: ${e.toString()}');
    }
  }

  @override
  Future<bool> sendOtp({required String phone, String language = 'ar'}) async {
    try {

      final response = await dio.post(
        ApiConstants.sendOtpEndpoint,
        data: {'phone': phone, 'language': language},
      );

      return response.data['success'] == true;
    } on DioException {
      // Re-throw DioException so the repository layer can convert it properly
      rethrow;
    } catch (e) {
      // Any non-Dio error (e.g., parsing) will still be wrapped in a generic Exception
      throw Exception('Send OTP failed: ${e.toString()}');
    }
  }

  @override
  Future<AuthResponseModel> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {

      final response = await dio.post(
        ApiConstants.verifyOtpEndpoint,
        data: {'phone': phone, 'otp': otp},
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is Map<String, dynamic>
          ? (responseData['data'] is Map<String, dynamic>
                ? responseData['data'] as Map<String, dynamic>
                : responseData)
          : <String, dynamic>{};

      final normalized = _normalizeAuthPayload(json);
      return AuthResponseModel.fromJson(normalized);
    } catch (e) {
      throw Exception('Verify OTP failed: ${e.toString()}');
    }
  }

  @override
  Future<bool> registerSendOtp({
    required String phone,
    String language = 'ar',
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.registerSendOtpEndpoint,
        data: {
          'phone': phone,
          'language': language,
        },
      );

      return response.data['success'] == true;
    } catch (e) {
      throw Exception('Register send OTP failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> registerVerifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.registerVerifyOtpEndpoint,
        data: {'phone': phone, 'otp': otp},
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is Map<String, dynamic>
          ? (responseData['data'] is Map<String, dynamic>
                ? responseData['data'] as Map<String, dynamic>
                : responseData)
          : <String, dynamic>{};

      return json;
    } catch (e) {
      throw Exception('Register verify OTP failed: ${e.toString()}');
    }
  }

  @override
  Future<AuthResponseModel> completeRegistration({
    required String phone,
    required String name,
    required String password,
    String language = 'ar',
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.completeRegistrationEndpoint,
        data: {
          'phone': phone,
          'name': name,
          'password': password,
          'language': language,
        },
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is Map<String, dynamic>
          ? (responseData['data'] is Map<String, dynamic>
                ? responseData['data'] as Map<String, dynamic>
                : responseData)
          : <String, dynamic>{};

      final normalized = _normalizeAuthPayload(json);
      return AuthResponseModel.fromJson(normalized);
    } catch (e) {
      throw Exception('Complete registration failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get(ApiConstants.profileEndpoint);
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is Map<String, dynamic>
          ? (responseData['data'] is Map<String, dynamic>
                ? responseData['data'] as Map<String, dynamic>
                : responseData)
          : <String, dynamic>{};
      final normalizedUser = _normalizeUserPayload(json);
      return UserModel.fromJson(normalizedUser);
    } catch (e) {
      throw Exception('Get profile failed: ${e.toString()}');
    }
  }

  @override
  Future<AuthResponseModel> refreshToken({required String refreshToken}) async {
    try {
      final response = await dio.post(
        ApiConstants.refreshTokenEndpoint,
        data: {'refreshToken': refreshToken},
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is Map<String, dynamic>
          ? (responseData['data'] is Map<String, dynamic>
                ? responseData['data'] as Map<String, dynamic>
                : responseData)
          : <String, dynamic>{};

      final normalized = _normalizeAuthPayload(json);
      return AuthResponseModel.fromJson(normalized);
    } catch (e) {
      throw Exception('Refresh token failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateProfile(UpdateProfileDto updateProfileDto) async {
    try {
      // Backend does not accept phone in update profile; send supported fields only
      final Map<String, dynamic> payload = <String, dynamic>{
        if (updateProfileDto.name != null) 'name': updateProfileDto.name,
        if (updateProfileDto.email != null) 'email': updateProfileDto.email,
        if (updateProfileDto.language != null)
          'language': updateProfileDto.language,
      };

      final response = await dio.put(
        ApiConstants.updateProfileEndpoint,
        data: payload,
      );

      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is Map<String, dynamic>
          ? (responseData['data'] is Map<String, dynamic>
                ? responseData['data'] as Map<String, dynamic>
                : responseData)
          : <String, dynamic>{};

      final normalizedUser = _normalizeUserPayload(json);
      return UserModel.fromJson(normalizedUser);
    } catch (e) {
      throw Exception('Update profile failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> refreshProfile() async {
    return getProfile();
  }

  @override
  Future<bool> updateLanguage(String language) async {
    try {
      final response = await dio.post(
        ApiConstants.updateLanguageEndpoint,
        data: {'language': language},
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Update language failed: ${e.toString()}');
    }
  }

  @override
  Future<bool> forgotPasswordSendOtp({
    required String phone,
    String language = 'ar',
  }) async {
    final response = await dio.post(
      ApiConstants.forgotPasswordSendOtpEndpoint,
      data: {'phone': phone, 'language': language},
    );
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) {
        return inner['success'] == true;
      }
      return data['success'] == true;
    }
    return false;
  }

  @override
  Future<String> forgotPasswordReset({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    final response = await dio.post(
      ApiConstants.forgotPasswordResetEndpoint,
      data: {
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) {
        return inner['message']?.toString() ?? '';
      }
      return data['message']?.toString() ?? '';
    }
    return '';
  }

  @override
  Future<void> deleteAccount() async {
    // #region agent log
    try {
      final logFile = File(r'c:\Users\HP\Desktop\loop\.cursor\debug.log');
      await logFile.writeAsString(
        '${jsonEncode({"location":"auth_remote_datasource.dart:419","message":"deleteAccount: entering try block","data":{"endpoint":ApiConstants.deleteAccountEndpoint},"timestamp":DateTime.now().millisecondsSinceEpoch,"sessionId":"debug-session","runId":"run1","hypothesisId":"A"})}\n',
        mode: FileMode.append,
      );
    } catch (_) {}
    // #endregion
    try {
      await dio.delete(ApiConstants.deleteAccountEndpoint);
      // #region agent log
      try {
        final logFile = File(r'c:\Users\HP\Desktop\loop\.cursor\debug.log');
        await logFile.writeAsString(
          '${jsonEncode({"location":"auth_remote_datasource.dart:420","message":"deleteAccount: success","data":{},"timestamp":DateTime.now().millisecondsSinceEpoch,"sessionId":"debug-session","runId":"run1","hypothesisId":"A"})}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      // #endregion
    } on DioException catch (e) {
      // #region agent log
      try {
        final logFile = File(r'c:\Users\HP\Desktop\loop\.cursor\debug.log');
        await logFile.writeAsString(
          '${jsonEncode({"location":"auth_remote_datasource.dart:422","message":"deleteAccount: caught DioException","data":{"exceptionType":e.runtimeType.toString(),"isDioException":true,"exceptionMessage":e.toString(),"dioResponseData":e.response?.data,"statusCode":e.response?.statusCode},"timestamp":DateTime.now().millisecondsSinceEpoch,"sessionId":"debug-session","runId":"run1","hypothesisId":"A"})}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      // #endregion
      // إعادة رمي DioException مباشرة للحفاظ على معلومات الخطأ الأصلية من السيرفر
      rethrow;
    } catch (e) {
      // #region agent log
      try {
        final logFile = File(r'c:\Users\HP\Desktop\loop\.cursor\debug.log');
        await logFile.writeAsString(
          '${jsonEncode({"location":"auth_remote_datasource.dart:422","message":"deleteAccount: caught exception","data":{"exceptionType":e.runtimeType.toString(),"isDioException":false,"exceptionMessage":e.toString()},"timestamp":DateTime.now().millisecondsSinceEpoch,"sessionId":"debug-session","runId":"run1","hypothesisId":"A"})}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      // #endregion
      throw Exception('Delete account failed: ${e.toString()}');
    }
  }
}
