import 'package:get_it/get_it.dart';
import '../../../core/network/dio_client.dart';
import '../data/datasources/subscription_remote_datasource.dart';
import '../data/repositories/subscription_repository_impl.dart';
import '../domain/repositories/subscription_repository.dart';
import '../domain/usecases/create_subscription_purchase_usecase.dart';
import '../domain/usecases/get_branch_subscription_plans_usecase.dart';
import '../domain/usecases/get_my_subscriptions_usecase.dart';
import '../domain/usecases/get_subscription_details_usecase.dart';
import '../domain/usecases/get_subscription_quote_usecase.dart';
import '../domain/usecases/get_subscription_usage_logs_usecase.dart';
import '../presentation/cubit/my_subscriptions_cubit.dart';
import '../presentation/cubit/subscription_plans_cubit.dart';
import '../presentation/cubit/subscription_purchase_cubit.dart';

void initSubscriptions() {
  final sl = GetIt.instance;

  sl.registerLazySingleton<SubscriptionRemoteDataSource>(
    () => SubscriptionRemoteDataSourceImpl(dio: DioClient.instance),
  );

  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(remote: sl()),
  );

  sl.registerLazySingleton(() => GetBranchSubscriptionPlansUseCase(sl()));
  sl.registerLazySingleton(() => GetSubscriptionQuoteUseCase(sl()));
  sl.registerLazySingleton(() => CreateSubscriptionPurchaseUseCase(sl()));
  sl.registerLazySingleton(() => GetMySubscriptionsUseCase(sl()));
  sl.registerLazySingleton(() => GetSubscriptionDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetSubscriptionUsageLogsUseCase(sl()));

  sl.registerFactory(
    () => SubscriptionPlansCubit(getPlans: sl<GetBranchSubscriptionPlansUseCase>()),
  );
  sl.registerFactory(
    () => MySubscriptionsCubit(getMy: sl<GetMySubscriptionsUseCase>()),
  );
  sl.registerFactory(
    () => SubscriptionPurchaseCubit(
      quoteUseCase: sl<GetSubscriptionQuoteUseCase>(),
      createUseCase: sl<CreateSubscriptionPurchaseUseCase>(),
    ),
  );
}
