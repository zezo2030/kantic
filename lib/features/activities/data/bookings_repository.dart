import '../../booking/data/models/booking_model.dart';
import '../domain/booking_status.dart';
import 'bookings_api.dart';

class PaginatedBookings {
  final List<BookingModel> items;
  final bool hasMore;
  final int nextPage;

  const PaginatedBookings({
    required this.items,
    required this.hasMore,
    required this.nextPage,
  });
}

abstract class BookingsRepository {
  Future<PaginatedBookings> fetch({
    BookingStatusFilter filter,
    int page,
    int pageSize,
  });
}

class BookingsRepositoryImpl implements BookingsRepository {
  final BookingsApi api;
  BookingsRepositoryImpl({required this.api});

  @override
  Future<PaginatedBookings> fetch({
    BookingStatusFilter filter = BookingStatusFilter.all,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await api.fetch(filter: filter, page: page, pageSize: pageSize);
    return PaginatedBookings(
      items: res.items,
      hasMore: res.hasMore,
      nextPage: res.nextPage,
    );
  }
}
