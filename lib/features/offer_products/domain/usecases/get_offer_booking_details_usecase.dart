import '../../data/models/offer_booking_model.dart';
import '../repositories/offer_products_repository.dart';

class GetOfferBookingDetailsUseCase {
  final OfferProductsRepository repository;

  GetOfferBookingDetailsUseCase(this.repository);

  Future<OfferBookingModel> call(String id) => repository.getBookingDetails(id);
}
