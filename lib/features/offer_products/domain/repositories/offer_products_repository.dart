import '../../data/models/offer_booking_model.dart';
import '../../data/models/offer_product_model.dart';
import '../../data/models/offer_ticket_model.dart';

abstract class OfferProductsRepository {
  Future<({
    List<OfferProductModel> ticketOffers,
    List<OfferProductModel> hoursOffers,
  })> getByBranch(String branchId);

  Future<Map<String, dynamic>> getQuote({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
  });

  Future<Map<String, dynamic>> createBooking({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
    String? contactPhone,
    required bool acceptedTerms,
  });

  Future<
      ({
        List<OfferBookingModel> items,
        int total,
        int page,
        int totalPages,
      })> getMyBookings({int page, int limit});

  Future<OfferBookingModel> getBookingDetails(String id);

  Future<List<OfferTicketModel>> getBookingTickets(String bookingId);
}
