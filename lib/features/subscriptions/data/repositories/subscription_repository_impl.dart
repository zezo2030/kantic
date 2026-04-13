import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_datasource.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_purchase_model.dart';
import '../models/subscription_usage_log_model.dart';
import '../../../../core/utils/api_json.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remote;

  SubscriptionRepositoryImpl({required this.remote});

  @override
  Future<List<SubscriptionPlanModel>> getPlansForBranch(String branchId) =>
      remote.fetchPlansForBranch(branchId);

  @override
  Future<Map<String, dynamic>> getQuote(String subscriptionPlanId) =>
      remote.quote(subscriptionPlanId);

  @override
  Future<Map<String, dynamic>> createPurchase({
    required String subscriptionPlanId,
    required bool acceptedTerms,
  }) =>
      remote.createPurchase(
        subscriptionPlanId: subscriptionPlanId,
        acceptedTerms: acceptedTerms,
      );

  @override
  Future<
      ({
        List<SubscriptionPurchaseModel> items,
        int total,
        int page,
        int totalPages,
      })> getMySubscriptions({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final data = await remote.fetchMySubscriptions(
      page: page,
      limit: limit,
      status: status,
    );
    final raw = data['subscriptions'] ?? data['items'] ?? [];
    final items = raw is List
        ? raw
              .map((e) => SubscriptionPurchaseModel.fromJson(asJsonMap(e)))
              .toList()
        : <SubscriptionPurchaseModel>[];
    return (
      items: items,
      total: toInt(data['total']) ?? items.length,
      page: toInt(data['page']) ?? page,
      totalPages: toInt(data['totalPages']) ?? 1,
    );
  }

  @override
  Future<SubscriptionPurchaseModel> getPurchaseDetails(String id) =>
      remote.fetchPurchaseDetails(id);

  @override
  Future<
      ({
        List<SubscriptionUsageLogModel> logs,
        int total,
        int page,
        int totalPages,
      })> getUsageLogs(
    String purchaseId, {
    int page = 1,
    int limit = 20,
  }) async {
    final data = await remote.fetchUsageLogs(
      purchaseId,
      page: page,
      limit: limit,
    );
    final raw = data['logs'] ?? [];
    final logs = raw is List
        ? raw
              .map((e) => SubscriptionUsageLogModel.fromJson(asJsonMap(e)))
              .toList()
        : <SubscriptionUsageLogModel>[];
    return (
      logs: logs,
      total: toInt(data['total']) ?? logs.length,
      page: toInt(data['page']) ?? page,
      totalPages: toInt(data['totalPages']) ?? 1,
    );
  }
}
