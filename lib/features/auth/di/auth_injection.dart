import 'package:get_it/get_it.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/network/dio_client.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/send_otp_usecase.dart';
import '../domain/usecases/verify_otp_usecase.dart';
import '../domain/usecases/register_send_otp_usecase.dart';
import '../domain/usecases/register_verify_otp_usecase.dart';
import '../domain/usecases/complete_registration_usecase.dart';
import '../domain/usecases/get_profile_usecase.dart';
import '../domain/usecases/refresh_token_usecase.dart';
import '../domain/usecases/update_profile_usecase.dart';
import '../domain/usecases/refresh_profile_usecase.dart';
import '../domain/usecases/update_language_usecase.dart';
import '../domain/usecases/delete_account_usecase.dart';
import '../domain/usecases/forgot_password_send_otp_usecase.dart';
import '../domain/usecases/forgot_password_reset_usecase.dart';
import '../presentation/cubit/auth_cubit.dart';
import '../../home/di/home_injection.dart';
import '../../booking/di/booking_injection.dart';
import '../../trips/di/trips_injection.dart';
import '../../wallet/di/wallet_injection.dart';
import '../../events/di/events_injection.dart';
import '../../notifications/di/notifications_injection.dart';
import '../../subscriptions/di/subscriptions_injection.dart';
import '../../offer_products/di/offer_products_injection.dart';
import '../../loyalty/di/loyalty_injection.dart';
import '../../tickets/di/tickets_injection.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  // Network
  sl.registerLazySingleton(() => DioClient.instance);

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => SendOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => RegisterSendOtpUseCase(sl()));
  sl.registerLazySingleton(() => RegisterVerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => CompleteRegistrationUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => RefreshTokenUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(repository: sl()));
  sl.registerLazySingleton(() => RefreshProfileUseCase(repository: sl()));
  sl.registerLazySingleton(() => UpdateLanguageUseCase(repository: sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(repository: sl()));
  sl.registerLazySingleton(() => ForgotPasswordSendOtpUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordResetUseCase(sl()));

  // Cubit
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl(),
      registerUseCase: sl(),
      sendOtpUseCase: sl(),
      verifyOtpUseCase: sl(),
      registerSendOtpUseCase: sl(),
      registerVerifyOtpUseCase: sl(),
      completeRegistrationUseCase: sl(),
      getProfileUseCase: sl(),
      refreshTokenUseCase: sl(),
      updateProfileUseCase: sl(),
      refreshProfileUseCase: sl(),
      updateLanguageUseCase: sl(),
      deleteAccountUseCase: sl(),
      forgotPasswordSendOtpUseCase: sl(),
      forgotPasswordResetUseCase: sl(),
    ),
  );

  // Initialize Home feature
  await initHome();

  // Initialize Booking feature
  initBookingInjection();
  initTickets();

  // Initialize Trips feature
  initTripsInjection();

  // Initialize Wallet feature
  initWalletInjection();

  // Initialize Events feature
  initEventsInjection();

  // Initialize Notifications feature
  initNotificationsInjection();

  // Subscriptions & catalog offer products (backend sync)
  initSubscriptions();
  initOfferProducts();

  // Loyalty feature
  initLoyaltyInjection();
}
