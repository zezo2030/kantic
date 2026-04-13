import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/usecases/get_home_data_usecase.dart';
import '../domain/usecases/get_branch_details_usecase.dart';
import '../domain/repositories/home_repository.dart';
import '../data/datasources/home_remote_datasource.dart';
import '../data/repositories/home_repository_impl.dart';
import '../presentation/cubit/home_cubit.dart';
import '../presentation/cubit/branch_details_cubit.dart';

final sl = GetIt.instance;

Future<void> initHome() async {
  // Data sources
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(dio: DioClient.instance),
  );

  // Repository
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl<HomeRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetHomeDataUseCase(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetBranchDetailsUseCase(repository: sl<HomeRepository>()));

  // Cubits
  sl.registerFactory(() => HomeCubit(getHomeDataUseCase: sl<GetHomeDataUseCase>()));
  sl.registerFactory(() => BranchDetailsCubit(getBranchDetailsUseCase: sl<GetBranchDetailsUseCase>()));
}
