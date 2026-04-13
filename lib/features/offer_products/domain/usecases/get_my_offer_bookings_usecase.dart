import '../../data/models/offer_booking_model.dart';
import '../repositories/offer_products_repository.dart';

class GetMyOfferBookingsUseCase {
  final OfferProductsRepository repository;

  GetMyOfferBookingsUseCase(this.repository);

  Future<
      ({
        List<OfferBookingModel> items,
        int total,
        int page,
        int totalPages,
      })> call({int page = 1, int limit = 10}) =>
      repository.getMyBookings(page: page, limit: limit);
}
