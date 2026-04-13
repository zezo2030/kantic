// Events Dependency Injection
import '../data/event_requests_api.dart';
import '../data/datasources/event_request_remote_datasource.dart';
import '../data/repositories/event_request_repository_impl.dart';
import '../domain/repositories/event_request_repository.dart';
import '../domain/usecases/get_event_requests_usecase.dart';
import '../domain/usecases/create_event_request_usecase.dart';
import '../domain/usecases/get_event_request_usecase.dart';
import '../presentation/cubit/event_request_cubit.dart';

import '../../auth/di/auth_injection.dart';

void initEventsInjection() {
  // API
  sl.registerLazySingleton<EventRequestsApi>(
    () => EventRequestsApi(),
  );

  // Data Sources
  sl.registerLazySingleton<EventRequestRemoteDataSource>(
    () => EventRequestRemoteDataSourceImpl(api: sl<EventRequestsApi>()),
  );

  // Repositories
  sl.registerLazySingleton<EventRequestRepository>(
    () => EventRequestRepositoryImpl(
      remoteDataSource: sl<EventRequestRemoteDataSource>(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton<GetEventRequestsUseCase>(
    () => GetEventRequestsUseCase(repository: sl<EventRequestRepository>()),
  );

  sl.registerLazySingleton<CreateEventRequestUseCase>(
    () => CreateEventRequestUseCase(repository: sl<EventRequestRepository>()),
  );

  sl.registerLazySingleton<GetEventRequestUseCase>(
    () => GetEventRequestUseCase(repository: sl<EventRequestRepository>()),
  );

  // Cubits
  sl.registerFactory<EventRequestCubit>(
    () => EventRequestCubit(
      getEventRequestsUseCase: sl<GetEventRequestsUseCase>(),
      createEventRequestUseCase: sl<CreateEventRequestUseCase>(),
      getEventRequestUseCase: sl<GetEventRequestUseCase>(),
      repository: sl<EventRequestRepository>(),
    ),
  );
}

