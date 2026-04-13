import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../data/datasources/trips_remote_datasource.dart';
import '../data/repositories/trips_repository_impl.dart';
import '../domain/repositories/trips_repository.dart';
import '../domain/usecases/cancel_trip_request_usecase.dart';
import '../domain/usecases/create_trip_request_usecase.dart';
import '../domain/usecases/get_trip_request_usecase.dart';
import '../domain/usecases/list_trip_requests_usecase.dart';
import '../domain/usecases/submit_trip_request_usecase.dart';
import '../domain/usecases/update_trip_request_usecase.dart';
import '../domain/usecases/upload_trip_participants_usecase.dart';
import '../presentation/cubit/create_trip_request_cubit.dart';
import '../presentation/cubit/trip_request_details_cubit.dart';
import '../presentation/cubit/trip_requests_cubit.dart';

final GetIt sl = GetIt.instance;

void initTripsInjection() {
  if (!sl.isRegistered<TripsRemoteDataSource>()) {
    sl.registerLazySingleton<TripsRemoteDataSource>(
      () => TripsRemoteDataSourceImpl(dio: sl<Dio>()),
    );
  }

  if (!sl.isRegistered<TripsRepository>()) {
    sl.registerLazySingleton<TripsRepository>(
      () => TripsRepositoryImpl(remoteDataSource: sl()),
    );
  }

  if (!sl.isRegistered<CreateTripRequestUseCase>()) {
    sl.registerLazySingleton(() => CreateTripRequestUseCase(sl()));
  }

  if (!sl.isRegistered<GetTripRequestUseCase>()) {
    sl.registerLazySingleton(() => GetTripRequestUseCase(sl()));
  }

  if (!sl.isRegistered<ListTripRequestsUseCase>()) {
    sl.registerLazySingleton(() => ListTripRequestsUseCase(sl()));
  }

  if (!sl.isRegistered<SubmitTripRequestUseCase>()) {
    sl.registerLazySingleton(() => SubmitTripRequestUseCase(sl()));
  }

  if (!sl.isRegistered<UploadTripParticipantsUseCase>()) {
    sl.registerLazySingleton(() => UploadTripParticipantsUseCase(sl()));
  }

  if (!sl.isRegistered<CancelTripRequestUseCase>()) {
    sl.registerLazySingleton(() => CancelTripRequestUseCase(sl()));
  }

  if (!sl.isRegistered<UpdateTripRequestUseCase>()) {
    sl.registerLazySingleton(() => UpdateTripRequestUseCase(sl()));
  }

  sl.registerFactory(() => TripRequestsCubit(listTripRequestsUseCase: sl()));

  sl.registerFactory(
    () => CreateTripRequestCubit(
      createTripRequestUseCase: sl(),
      uploadTripParticipantsUseCase: sl(),
      submitTripRequestUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => TripRequestDetailsCubit(
      getTripRequestUseCase: sl(),
      submitTripRequestUseCase: sl(),
      uploadTripParticipantsUseCase: sl(),
      cancelTripRequestUseCase: sl(),
      repository: sl(),
    ),
  );
}
