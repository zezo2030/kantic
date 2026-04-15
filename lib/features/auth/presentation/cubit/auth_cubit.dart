import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/register_send_otp_usecase.dart';
import '../../domain/usecases/register_verify_otp_usecase.dart';
import '../../domain/usecases/complete_registration_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/refresh_profile_usecase.dart';
import '../../domain/usecases/update_language_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/forgot_password_send_otp_usecase.dart';
import '../../domain/usecases/forgot_password_reset_usecase.dart';
import '../../data/models/update_profile_dto.dart';
import '../../../../core/errors/failures.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final RegisterSendOtpUseCase registerSendOtpUseCase;
  final RegisterVerifyOtpUseCase registerVerifyOtpUseCase;
  final CompleteRegistrationUseCase completeRegistrationUseCase;
  final GetProfileUseCase getProfileUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final RefreshProfileUseCase refreshProfileUseCase;
  final UpdateLanguageUseCase updateLanguageUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;
  final ForgotPasswordSendOtpUseCase forgotPasswordSendOtpUseCase;
  final ForgotPasswordResetUseCase forgotPasswordResetUseCase;
  final SecureStorageService _storageService =
      GetIt.instance<SecureStorageService>();

  /// Convert UserEntity to JSON string for storage
  String _userEntityToJson(UserEntity user) {
    final userModel = UserModel.fromEntity(user);
    return jsonEncode(userModel.toJson());
  }

  AuthCubit({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.registerSendOtpUseCase,
    required this.registerVerifyOtpUseCase,
    required this.completeRegistrationUseCase,
    required this.getProfileUseCase,
    required this.refreshTokenUseCase,
    required this.updateProfileUseCase,
    required this.refreshProfileUseCase,
    required this.updateLanguageUseCase,
    required this.deleteAccountUseCase,
    required this.forgotPasswordSendOtpUseCase,
    required this.forgotPasswordResetUseCase,
  }) : super(AuthInitial());

  Future<void> forgotPasswordSendOtp({
    required String phone,
    String language = 'ar',
  }) async {
    emit(AuthLoading());

    final result = await forgotPasswordSendOtpUseCase(
      phone: phone,
      language: language,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (success) {
        if (success) {
          emit(ForgotPasswordOtpSent(phone: phone));
        } else {
          emit(AuthError(message: 'operation_failed'));
        }
      },
    );
  }

  Future<void> forgotPasswordReset({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    emit(AuthLoading());

    final result = await forgotPasswordResetUseCase(
      phone: phone,
      otp: otp,
      newPassword: newPassword,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (message) => emit(ForgotPasswordResetSuccess(message: message)),
    );
  }

  // Login with phone and password
  Future<void> login({required String phone, required String password}) async {
    emit(AuthLoading());

    final result = await loginUseCase(phone: phone, password: password);

    result.fold((failure) => emit(AuthError(message: failure.message)), (
      authResponse,
    ) async {
      // Save tokens
      await _storageService.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      // Save user data as JSON
      await _storageService.saveUserData(_userEntityToJson(authResponse.user));

      // Register FCM token after login
      try {
        await FirebaseService.instance.registerTokenIfUserLoggedIn();
      } catch (e) {
      }

      emit(Authenticated(user: authResponse.user));
    });
  }

  // Register with email and password
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String language = 'ar',
  }) async {
    emit(AuthLoading());

    final result = await registerUseCase(
      name: name,
      email: email,
      password: password,
      phone: phone,
      language: language,
    );

    result.fold((failure) => emit(AuthError(message: failure.message)), (
      authResponse,
    ) async {
      // Save tokens
      await _storageService.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      // Save user data as JSON
      await _storageService.saveUserData(_userEntityToJson(authResponse.user));

      // Register FCM token after registration
      try {
        await FirebaseService.instance.registerTokenIfUserLoggedIn();
      } catch (e) {
      }

      emit(RegisterSuccess(authResponse: authResponse));
    });
  }

  // Send OTP for login
  Future<void> sendOtp({required String phone, String language = 'ar'}) async {
    emit(AuthLoading());

    final result = await sendOtpUseCase(phone: phone, language: language);

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message));
      },
      (success) {
        emit(OtpSent(phone: phone));
      },
    );
  }

  // Verify OTP for login
  Future<void> verifyOtp({required String phone, required String otp}) async {
    emit(AuthLoading());

    final result = await verifyOtpUseCase(phone: phone, otp: otp);

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message));
      },
      (authResponse) async {
        // Save tokens
        await _storageService.saveTokens(
          authResponse.accessToken,
          authResponse.refreshToken,
        );

        // Save user data
        await _storageService.saveUserData(authResponse.user.toString());

        // Register FCM token after OTP verification
        try {
          await FirebaseService.instance.registerTokenIfUserLoggedIn();
        } catch (e) {
        }

        emit(OtpVerified(authResponse: authResponse));
      },
    );
  }

  // Send OTP for registration
  Future<void> registerSendOtp({
    required String phone,
    String language = 'ar',
  }) async {
    emit(AuthLoading());

    final result = await registerSendOtpUseCase(
      phone: phone,
      language: language,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (success) => emit(RegisterOtpSent(phone: phone)),
    );
  }

  // Verify OTP for registration
  Future<void> registerVerifyOtp({
    required String phone,
    required String otp,
  }) async {
    emit(AuthLoading());

    final result = await registerVerifyOtpUseCase(phone: phone, otp: otp);

    result.fold((failure) => emit(AuthError(message: failure.message)), (
      response,
    ) {
      // Check if registration requires completion
      if (response['requiresCompletion'] == true) {
        emit(RegistrationIncomplete(phone: phone));
      } else {
        emit(AuthError(message: 'Unexpected response from server'));
      }
    });
  }

  // Complete registration with name and password
  Future<void> completeRegistration({
    required String phone,
    required String name,
    required String password,
    String language = 'ar',
  }) async {
    emit(AuthLoading());

    final result = await completeRegistrationUseCase(
      phone: phone,
      name: name,
      password: password,
      language: language,
    );

    result.fold((failure) => emit(AuthError(message: failure.message)), (
      authResponse,
    ) async {
      // Save tokens
      await _storageService.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      // Save user data as JSON
      await _storageService.saveUserData(_userEntityToJson(authResponse.user));

      // Register FCM token after complete registration
      try {
        await FirebaseService.instance.registerTokenIfUserLoggedIn();
      } catch (e) {
      }

      emit(RegisterSuccess(authResponse: authResponse));
    });
  }

  // Get user profile
  Future<void> getProfile() async {
    emit(AuthLoading());

    final result = await getProfileUseCase();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) async {
        // Save user data as JSON if not already saved
        await _storageService.saveUserData(_userEntityToJson(user));
        
        // Register FCM token if user is authenticated
        try {
          await FirebaseService.instance.registerTokenIfUserLoggedIn();
        } catch (e) {
        }
        
        emit(Authenticated(user: user));
      },
    );
  }

  // Refresh token
  Future<void> refreshToken() async {
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null) {
      emit(Unauthenticated());
      return;
    }

    final result = await refreshTokenUseCase(refreshToken: refreshToken);

    result.fold((failure) => emit(Unauthenticated()), (authResponse) async {
      // Save new tokens
      await _storageService.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      // Save user data as JSON
      await _storageService.saveUserData(_userEntityToJson(authResponse.user));

      // Register FCM token after token refresh
      try {
        await FirebaseService.instance.registerTokenIfUserLoggedIn();
      } catch (e) {
      }

      emit(Authenticated(user: authResponse.user));
    });
  }

  // Logout
  Future<void> logout() async {
    // Unregister FCM token before logout
    try {
      await FirebaseService.instance.unregisterDevice();
    } catch (e) {
    }
    
    await _storageService.clearTokens();
    emit(Unauthenticated());
  }

  // Enter as guest
  Future<void> enterAsGuest() async {
    emit(Guest());
  }

  // Check if user is logged in
  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _storageService.isLoggedIn();
    if (isLoggedIn) {
      await getProfile();
      // Register FCM token if user is already logged in
      try {
        await FirebaseService.instance.registerTokenIfUserLoggedIn();
      } catch (e) {
      }
    } else {
      emit(Unauthenticated());
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? language,
    String? phone,
  }) async {
    emit(ProfileUpdating());

    final updateProfileDto = UpdateProfileDto(
      name: name,
      email: email,
      language: language,
      phone: phone,
    );

    final result = await updateProfileUseCase(updateProfileDto);

    result.fold(
      (failure) => emit(ProfileUpdateError(message: failure.message)),
      (user) {
        emit(ProfileUpdated(user: user));
        // Also update the authenticated state with new user data
        emit(Authenticated(user: user));
      },
    );
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    emit(AuthLoading());

    final result = await refreshProfileUseCase();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(Authenticated(user: user)),
    );
  }

  // Update user language
  Future<void> updateLanguage(String language) async {
    emit(LanguageUpdating());

    final result = await updateLanguageUseCase(language);

    result.fold(
      (failure) => emit(LanguageUpdateError(message: failure.message)),
      (success) {
        emit(LanguageUpdated(language: language));
        // Refresh profile to get updated user data
        refreshProfile();
      },
    );
  }

  // Delete user account
  Future<void> deleteAccount() async {
    emit(AccountDeleting());

    final result = await deleteAccountUseCase();

    result.fold(
      (failure) {
        // Log the failure for debugging
        
        // Extract and format error message
        final errorMessage = _formatDeleteAccountError(failure);
        emit(AccountDeleteError(message: errorMessage));
      },
      (_) async {
        // Unregister FCM token before logout
        try {
          await FirebaseService.instance.unregisterDevice();
        } catch (e) {
        }
        
        // Clear tokens and user data
        await _storageService.clearTokens();
        emit(AccountDeleted());
        // Also emit Unauthenticated to trigger navigation
        emit(Unauthenticated());
      },
    );
  }

  // Format delete account error messages for better user experience
  String _formatDeleteAccountError(Failure failure) {
    final message = failure.message.toLowerCase();
    
    
    // Check for specific error messages from backend (case-insensitive)
    if (message.contains('active bookings') || 
        message.contains('support tickets') ||
        message.contains('cancel bookings') ||
        message.contains('cannot delete account with active')) {
      return 'delete_account_active_bookings';
    }
    
    if (message.contains('wallet transactions') || 
        message.contains('contact support') ||
        message.contains('cannot delete account with wallet')) {
      return 'delete_account_wallet_transactions';
    }
    
    // Check failure type for network/server errors
    if (failure is NetworkFailure || 
        failure is TimeoutFailure ||
        message.contains('connection') || 
        message.contains('timeout') ||
        message.contains('network') ||
        message.contains('unable to connect')) {
      return 'delete_account_network_error';
    }
    
    if (failure is ServerFailure || 
        message.contains('server') ||
        message.contains('internal error') ||
        message.contains('bad request')) {
      return 'delete_account_server_error';
    }
    
    // Default error message
    return 'delete_account_unknown_error';
  }
}
