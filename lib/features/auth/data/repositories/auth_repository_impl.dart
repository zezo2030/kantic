import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/auth_response_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/update_profile_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuthResponseEntity>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.login(
        phone: phone,
        password: password,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String language = 'ar',
  }) async {
    try {
      final result = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        language: language,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> sendOtp({
    required String phone,
    String language = 'ar',
  }) async {
    try {
      final result = await remoteDataSource.sendOtp(
        phone: phone,
        language: language,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final result = await remoteDataSource.verifyOtp(
        phone: phone,
        otp: otp,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> registerSendOtp({
    required String phone,
    String language = 'ar',
  }) async {
    try {
      final result = await remoteDataSource.registerSendOtp(
        phone: phone,
        language: language,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> registerVerifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final result = await remoteDataSource.registerVerifyOtp(
        phone: phone,
        otp: otp,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> completeRegistration({
    required String phone,
    required String name,
    required String password,
    String language = 'ar',
  }) async {
    try {
      final result = await remoteDataSource.completeRegistration(
        phone: phone,
        name: name,
        password: password,
        language: language,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getProfile() async {
    try {
      final result = await remoteDataSource.getProfile();
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResponseEntity>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final result = await remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile(
    UpdateProfileDto updateProfileDto,
  ) async {
    try {
      final result = await remoteDataSource.updateProfile(updateProfileDto);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> refreshProfile() async {
    try {
      final result = await remoteDataSource.refreshProfile();
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateLanguage(String language) async {
    try {
      final result = await remoteDataSource.updateLanguage(language);
      return Right(result);
    } on DioException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    // #region agent log
    try {
      final logFile = File(r'c:\Users\HP\Desktop\loop\.cursor\debug.log');
      await logFile.writeAsString(
        '${jsonEncode({"location":"auth_repository_impl.dart:232","message":"deleteAccount: entering","data":{},"timestamp":DateTime.now().millisecondsSinceEpoch,"sessionId":"debug-session","runId":"run1","hypothesisId":"B"})}\n',
        mode: FileMode.append,
      );
    } catch (_) {}
    // #endregion
    try {
      await remoteDataSource.deleteAccount();
      // #region agent log
      try {
        final logFile = File(r'c:\Users\HP\Desktop\loop\.cursor\debug.log');
        await logFile.writeAsString(
          '${jsonEncode({"location":"auth_repository_impl.dart:234","message":"deleteAccount: success","data":{},"timestamp":DateTime.now().millisecondsSinceEpoch,"sessionId":"debug-session","runId":"run1","hypothesisId":"B"})}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      // #endregion
      return const Right(null);
    } on DioException catch (e) {
      // #region agent log
      try {
        final logFile = File(r'c:\Users\HP\Desktop\loop\.cursor\debug.log');
        await logFile.writeAsString(
          '${jsonEncode({"location":"auth_repository_impl.dart:236","message":"deleteAccount: caught DioException","data":{"responseData":e.response?.data,"statusCode":e.response?.statusCode},"timestamp":DateTime.now().millisecondsSinceEpoch,"sessionId":"debug-session","runId":"run1","hypothesisId":"B"})}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      // #endregion
      return Left(e.toFailure());
    } catch (e) {
      // #region agent log
      try {
        final logFile = File(r'c:\Users\HP\Desktop\loop\.cursor\debug.log');
        await logFile.writeAsString(
          '${jsonEncode({"location":"auth_repository_impl.dart:238","message":"deleteAccount: caught generic exception","data":{"exceptionType":e.runtimeType.toString(),"exceptionMessage":e.toString()},"timestamp":DateTime.now().millisecondsSinceEpoch,"sessionId":"debug-session","runId":"run1","hypothesisId":"B"})}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
      // #endregion
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
