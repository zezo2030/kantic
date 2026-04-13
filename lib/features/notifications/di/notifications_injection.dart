import 'package:get_it/get_it.dart';
import '../data/datasources/notifications_remote_datasource.dart';
import '../data/repositories/notifications_repository_impl.dart';
import '../domain/repositories/notifications_repository.dart';
import '../domain/usecases/get_notifications_usecase.dart';
import '../domain/usecases/get_unread_count_usecase.dart';
import '../domain/usecases/mark_notification_read_usecase.dart';
import '../domain/usecases/delete_notification_usecase.dart';
import '../presentation/cubit/notifications_cubit.dart';

final GetIt sl = GetIt.instance;

void initNotificationsInjection() {
  // Data sources
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(dio: sl()),
  );

  // Repository
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetNotificationsUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(repository: sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => MarkAllNotificationsReadUseCase(repository: sl()),
  );
  sl.registerLazySingleton(() => DeleteNotificationUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => DeleteAllNotificationsUseCase(repository: sl()),
  );

  // Cubit
  sl.registerFactory(
    () => NotificationsCubit(
      getNotificationsUseCase: sl(),
      getUnreadCountUseCase: sl(),
      markNotificationReadUseCase: sl(),
      markAllNotificationsReadUseCase: sl(),
      deleteNotificationUseCase: sl(),
      deleteAllNotificationsUseCase: sl(),
    ),
  );
}
