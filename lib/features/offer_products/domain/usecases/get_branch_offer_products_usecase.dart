import '../../data/models/offer_product_model.dart';
import '../repositories/offer_products_repository.dart';

class GetBranchOfferProductsUseCase {
  final OfferProductsRepository repository;

  GetBranchOfferProductsUseCase(this.repository);

  Future<
      ({
        List<OfferProductModel> ticketOffers,
        List<OfferProductModel> hoursOffers,
      })> call(String branchId) =>
      repository.getByBranch(branchId);
}
