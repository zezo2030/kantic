import '../../../../core/utils/api_json.dart';
import '../../domain/repositories/offer_products_repository.dart';
import '../datasources/offer_products_remote_datasource.dart';
import '../models/offer_booking_model.dart';
import '../models/offer_product_model.dart';
import '../models/offer_ticket_model.dart';

class OfferProductsRepositoryImpl implements OfferProductsRepository {
  final OfferProductsRemoteDataSource remote;

  OfferProductsRepositoryImpl({required this.remote});

  List<OfferProductModel> _mapProducts(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => OfferProductModel.fromJson(asJsonMap(e))).toList();
  }

  @override
  Future<
      ({
        List<OfferProductModel> ticketOffers,
        List<OfferProductModel> hoursOffers,
      })> getByBranch(String branchId) async {
    final data = await remote.fetchByBranch(branchId);
    return (
      ticketOffers: _mapProducts(data['ticketOffers']),
      hoursOffers: _mapProducts(data['hoursOffers']),
    );
  }

  @override
  Future<Map<String, dynamic>> getQuote({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
  }) =>
      remote.quote(offerProductId: offerProductId, addOns: addOns);

  @override
  Future<Map<String, dynamic>> createBooking({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
    String? contactPhone,
    required bool acceptedTerms,
  }) =>
      remote.createBooking(
        offerProductId: offerProductId,
        addOns: addOns,
        contactPhone: contactPhone,
        acceptedTerms: acceptedTerms,
      );

  @override
  Future<
      ({
        List<OfferBookingModel> items,
        int total,
        int page,
        int totalPages,
      })> getMyBookings({int page = 1, int limit = 10}) async {
    final data = await remote.fetchMyBookings(page: page, limit: limit);
    final raw = data['bookings'] ?? [];
    final items = raw is List
        ? raw.map((e) => OfferBookingModel.fromJson(asJsonMap(e))).toList()
        : <OfferBookingModel>[];
    return (
      items: items,
      total: toInt(data['total']) ?? items.length,
      page: toInt(data['page']) ?? page,
      totalPages: toInt(data['totalPages']) ?? 1,
    );
  }

  @override
  Future<OfferBookingModel> getBookingDetails(String id) async {
    final data = await remote.fetchBookingDetails(id);
    return OfferBookingModel.fromJson(data);
  }

  @override
  Future<List<OfferTicketModel>> getBookingTickets(String bookingId) async {
    final data = await remote.fetchBookingTickets(bookingId);
    final raw = data['tickets'] ?? [];
    if (raw is! List) return [];
    return raw.map((e) => OfferTicketModel.fromJson(asJsonMap(e))).toList();
  }
}
