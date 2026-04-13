import 'package:get_it/get_it.dart';
import '../../../core/network/dio_client.dart';
import '../data/datasources/offer_products_remote_datasource.dart';
import '../data/repositories/offer_products_repository_impl.dart';
import '../domain/repositories/offer_products_repository.dart';
import '../domain/usecases/create_offer_booking_usecase.dart';
import '../domain/usecases/get_branch_offer_products_usecase.dart';
import '../domain/usecases/get_my_offer_bookings_usecase.dart';
import '../domain/usecases/get_offer_booking_details_usecase.dart';
import '../domain/usecases/get_offer_booking_tickets_usecase.dart';
import '../domain/usecases/get_offer_quote_usecase.dart';
import '../presentation/cubit/my_offer_bookings_cubit.dart';
import '../presentation/cubit/offer_booking_cubit.dart';
import '../presentation/cubit/offer_products_cubit.dart';

void initOfferProducts() {
  final sl = GetIt.instance;

  sl.registerLazySingleton<OfferProductsRemoteDataSource>(
    () => OfferProductsRemoteDataSourceImpl(dio: DioClient.instance),
  );

  sl.registerLazySingleton<OfferProductsRepository>(
    () => OfferProductsRepositoryImpl(remote: sl()),
  );

  sl.registerLazySingleton(() => GetBranchOfferProductsUseCase(sl()));
  sl.registerLazySingleton(() => GetOfferQuoteUseCase(sl()));
  sl.registerLazySingleton(() => CreateOfferBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetMyOfferBookingsUseCase(sl()));
  sl.registerLazySingleton(() => GetOfferBookingDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetOfferBookingTicketsUseCase(sl()));

  sl.registerFactory(
    () => OfferProductsCubit(getBranch: sl<GetBranchOfferProductsUseCase>()),
  );
  sl.registerFactory(
    () => OfferBookingCubit(
      quoteUseCase: sl<GetOfferQuoteUseCase>(),
      createUseCase: sl<CreateOfferBookingUseCase>(),
    ),
  );
  sl.registerFactory(
    () => MyOfferBookingsCubit(getMy: sl<GetMyOfferBookingsUseCase>()),
  );
}
