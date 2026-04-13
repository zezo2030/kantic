import '../../data/models/subscription_usage_log_model.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionUsageLogsUseCase {
  final SubscriptionRepository repository;

  GetSubscriptionUsageLogsUseCase(this.repository);

  Future<
      ({
        List<SubscriptionUsageLogModel> logs,
        int total,
        int page,
        int totalPages,
      })> call(
    String purchaseId, {
    int page = 1,
    int limit = 20,
  }) =>
      repository.getUsageLogs(purchaseId, page: page, limit: limit);
}
