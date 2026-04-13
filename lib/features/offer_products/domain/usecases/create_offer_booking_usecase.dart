import '../repositories/offer_products_repository.dart';

class CreateOfferBookingUseCase {
  final OfferProductsRepository repository;

  CreateOfferBookingUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
    String? contactPhone,
    required bool acceptedTerms,
  }) =>
      repository.createBooking(
        offerProductId: offerProductId,
        addOns: addOns,
        contactPhone: contactPhone,
        acceptedTerms: acceptedTerms,
      );
}
