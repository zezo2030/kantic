import '../../data/models/subscription_purchase_model.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionDetailsUseCase {
  final SubscriptionRepository repository;

  GetSubscriptionDetailsUseCase(this.repository);

  Future<SubscriptionPurchaseModel> call(String id) =>
      repository.getPurchaseDetails(id);
}
