import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../data/datasources/loyalty_remote_datasource.dart';
import '../data/repositories/loyalty_repository_impl.dart';
import '../domain/repositories/loyalty_repository.dart';
import '../domain/usecases/get_loyalty_info_usecase.dart';
import '../domain/usecases/redeem_ticket_usecase.dart';
import '../presentation/cubit/loyalty_cubit.dart';

final GetIt sl = GetIt.instance;

void initLoyaltyInjection() {
  sl.registerLazySingleton<LoyaltyRemoteDataSource>(
    () => LoyaltyRemoteDataSourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<LoyaltyRepository>(
    () => LoyaltyRepositoryImpl(remote: sl()),
  );

  sl.registerLazySingleton(() => GetLoyaltyInfoUseCase(sl()));
  sl.registerLazySingleton(() => RedeemTicketUseCase(sl()));

  sl.registerFactory(
    () => LoyaltyCubit(
      getLoyaltyInfoUseCase: sl(),
      redeemTicketUseCase: sl(),
    ),
  );
}
