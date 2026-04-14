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
  // Idempotent: main() and feature flows may both call this.
  if (!sl.isRegistered<PaymentRemoteDataSource>()) {
    sl.registerLazySingleton<PaymentRemoteDataSource>(
      () => PaymentRemoteDataSourceImpl(dio: DioClient.instance),
    );
  }

  if (!sl.isRegistered<PaymentRepository>()) {
    sl.registerLazySingleton<PaymentRepository>(
      () => PaymentRepositoryImpl(remote: sl<PaymentRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<CreatePaymentIntentUseCase>()) {
    sl.registerLazySingleton<CreatePaymentIntentUseCase>(
      () => CreatePaymentIntentUseCase(repository: sl<PaymentRepository>()),
    );
  }
  if (!sl.isRegistered<ConfirmPaymentUseCase>()) {
    sl.registerLazySingleton<ConfirmPaymentUseCase>(
      () => ConfirmPaymentUseCase(repository: sl<PaymentRepository>()),
    );
  }

  if (!sl.isRegistered<PaymentCubit>()) {
    sl.registerFactory<PaymentCubit>(
      () => PaymentCubit(
        createIntentUseCase: sl<CreatePaymentIntentUseCase>(),
        confirmPaymentUseCase: sl<ConfirmPaymentUseCase>(),
      ),
    );
  }
}
