import 'package:get_it/get_it.dart';
import '../../../core/network/dio_client.dart';
import '../data/datasources/tickets_remote_datasource.dart';

final sl = GetIt.instance;

void initTickets() {
  sl.registerLazySingleton<TicketsRemoteDataSource>(
    () => TicketsRemoteDataSourceImpl(dio: DioClient.instance),
  );
}
