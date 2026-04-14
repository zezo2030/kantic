import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../data/datasources/wallet_remote_datasource.dart';
import '../data/repositories/wallet_repository_impl.dart';
import '../domain/repositories/wallet_repository.dart';
import '../domain/usecases/get_wallet_usecase.dart';
import '../domain/usecases/get_transactions_usecase.dart';
import '../domain/usecases/recharge_wallet_usecase.dart';
import '../presentation/cubit/wallet_cubit.dart';

final GetIt sl = GetIt.instance;

void initWalletInjection() {
  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(remote: sl()),
  );

  sl.registerLazySingleton(() => GetWalletUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => RechargeWalletUseCase(sl()));

  sl.registerFactory(
    () => WalletCubit(
      getWalletUseCase: sl(),
      getTransactionsUseCase: sl(),
      rechargeWalletUseCase: sl(),
    ),
  );
}
