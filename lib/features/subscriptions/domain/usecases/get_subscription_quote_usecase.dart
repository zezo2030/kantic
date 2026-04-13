import '../repositories/subscription_repository.dart';

class GetSubscriptionQuoteUseCase {
  final SubscriptionRepository repository;

  GetSubscriptionQuoteUseCase(this.repository);

  Future<Map<String, dynamic>> call(String subscriptionPlanId) =>
      repository.getQuote(subscriptionPlanId);
}
