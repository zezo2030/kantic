import '../../data/models/subscription_purchase_model.dart';
import '../repositories/subscription_repository.dart';

class GetMySubscriptionsUseCase {
  final SubscriptionRepository repository;

  GetMySubscriptionsUseCase(this.repository);

  Future<
      ({
        List<SubscriptionPurchaseModel> items,
        int total,
        int page,
        int totalPages,
      })> call({
    int page = 1,
    int limit = 10,
    String? status,
  }) =>
      repository.getMySubscriptions(page: page, limit: limit, status: status);
}
