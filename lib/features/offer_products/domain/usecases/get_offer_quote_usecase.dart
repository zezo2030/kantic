import '../repositories/offer_products_repository.dart';

class GetOfferQuoteUseCase {
  final OfferProductsRepository repository;

  GetOfferQuoteUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
  }) =>
      repository.getQuote(offerProductId: offerProductId, addOns: addOns);
}
