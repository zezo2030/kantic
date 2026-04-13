import '../../data/models/subscription_plan_model.dart';
import '../../data/models/subscription_purchase_model.dart';
import '../../data/models/subscription_usage_log_model.dart';

abstract class SubscriptionRepository {
  Future<List<SubscriptionPlanModel>> getPlansForBranch(String branchId);
  Future<Map<String, dynamic>> getQuote(String subscriptionPlanId);
  Future<Map<String, dynamic>> createPurchase({
    required String subscriptionPlanId,
    required bool acceptedTerms,
  });
  Future<({
    List<SubscriptionPurchaseModel> items,
    int total,
    int page,
    int totalPages,
  })> getMySubscriptions({
    int page,
    int limit,
    String? status,
  });
  Future<SubscriptionPurchaseModel> getPurchaseDetails(String id);
  Future<({
    List<SubscriptionUsageLogModel> logs,
    int total,
    int page,
    int totalPages,
  })> getUsageLogs(String purchaseId, {int page, int limit});
}
