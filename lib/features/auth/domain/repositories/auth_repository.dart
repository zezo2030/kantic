import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_response_entity.dart';
import '../entities/user_entity.dart';
import '../../data/models/update_profile_dto.dart';

abstract class AuthRepository {
  // Login with phone and password
  Future<Either<Failure, AuthResponseEntity>> login({
    required String phone,
    required String password,
  });

  // Register with email and password
  Future<Either<Failure, AuthResponseEntity>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String language = 'ar',
  });

  // Send OTP for login
  Future<Either<Failure, bool>> sendOtp({
    required String phone,
    String language = 'ar',
  });

  // Verify OTP for login
  Future<Either<Failure, AuthResponseEntity>> verifyOtp({
    required String phone,
    required String otp,
  });

  // Send OTP for registration
  Future<Either<Failure, bool>> registerSendOtp({
    required String phone,
    String language = 'ar',
  });

  // Verify OTP for registration
  Future<Either<Failure, Map<String, dynamic>>> registerVerifyOtp({
    required String phone,
    required String otp,
  });

  // Complete registration with name and password
  Future<Either<Failure, AuthResponseEntity>> completeRegistration({
    required String phone,
    required String name,
    required String password,
    String language = 'ar',
  });

  // Get user profile
  Future<Either<Failure, UserEntity>> getProfile();

  // Refresh access token
  Future<Either<Failure, AuthResponseEntity>> refreshToken({
    required String refreshToken,
  });

  // Update user profile
  Future<Either<Failure, UserEntity>> updateProfile(
    UpdateProfileDto updateProfileDto,
  );

  // Refresh user profile data
  Future<Either<Failure, UserEntity>> refreshProfile();

  // Update user language
  Future<Either<Failure, bool>> updateLanguage(String language);

  // Delete user account
  Future<Either<Failure, void>> deleteAccount();
}
