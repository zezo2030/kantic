import '../../data/models/offer_ticket_model.dart';
import '../repositories/offer_products_repository.dart';

class GetOfferBookingTicketsUseCase {
  final OfferProductsRepository repository;

  GetOfferBookingTicketsUseCase(this.repository);

  Future<List<OfferTicketModel>> call(String bookingId) =>
      repository.getBookingTickets(bookingId);
}
