import 'package:get_it/get_it.dart';
import '../../../core/network/dio_client.dart';
import '../data/datasources/payment_remote_datasource.dart';
import '../data/repositories/payment_repository_impl.dart';
import '../domain/repositories/payment_repository.dart';
import '../domain/usecases/create_payment_intent_usecase.dart';
import '../domain/usecases/confirm_payment_usecase.dart';
import '../presentation/cubit/payment_cubit.dart';

final sl = GetIt.instance;

void initPayments() {
  // Data source
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(dio: DioClient.instance),
  );

  // Repository
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(remote: sl<PaymentRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(
    () => CreatePaymentIntentUseCase(repository: sl<PaymentRepository>()),
  );
  sl.registerLazySingleton(
    () => ConfirmPaymentUseCase(repository: sl<PaymentRepository>()),
  );

  // Cubit
  sl.registerFactory(
    () => PaymentCubit(
      createIntentUseCase: sl<CreatePaymentIntentUseCase>(),
      confirmPaymentUseCase: sl<ConfirmPaymentUseCase>(),
    ),
  );
}
