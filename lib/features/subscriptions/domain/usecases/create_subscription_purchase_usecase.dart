import '../repositories/subscription_repository.dart';

class CreateSubscriptionPurchaseUseCase {
  final SubscriptionRepository repository;

  CreateSubscriptionPurchaseUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required String subscriptionPlanId,
    required bool acceptedTerms,
  }) =>
      repository.createPurchase(
        subscriptionPlanId: subscriptionPlanId,
        acceptedTerms: acceptedTerms,
      );
}
