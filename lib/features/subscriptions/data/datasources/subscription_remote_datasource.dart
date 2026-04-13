import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/api_json.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_purchase_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<List<SubscriptionPlanModel>> fetchPlansForBranch(String branchId);
  Future<Map<String, dynamic>> quote(String subscriptionPlanId);
  Future<Map<String, dynamic>> createPurchase({
    required String subscriptionPlanId,
    required bool acceptedTerms,
  });
  Future<Map<String, dynamic>> fetchMySubscriptions({
    int page = 1,
    int limit = 10,
    String? status,
  });
  Future<SubscriptionPurchaseModel> fetchPurchaseDetails(String id);
  Future<Map<String, dynamic>> fetchUsageLogs(
    String purchaseId, {
    int page = 1,
    int limit = 20,
  });
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final Dio dio;

  SubscriptionRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<SubscriptionPlanModel>> fetchPlansForBranch(String branchId) async {
    final res = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.branchSubscriptionPlans(branchId)}',
    );
    final body = unwrapData(res.data);
    final plansRaw = body['plans'] ?? body['items'] ?? body;
    if (plansRaw is List) {
      return plansRaw
          .map((e) => SubscriptionPlanModel.fromJson(asJsonMap(e)))
          .toList();
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> quote(String subscriptionPlanId) async {
    final res = await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.subscriptionQuoteEndpoint}',
      data: {'subscriptionPlanId': subscriptionPlanId},
    );
    return unwrapData(res.data);
  }

  @override
  Future<Map<String, dynamic>> createPurchase({
    required String subscriptionPlanId,
    required bool acceptedTerms,
  }) async {
    final res = await dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.subscriptionPurchasesEndpoint}',
      data: {
        'subscriptionPlanId': subscriptionPlanId,
        'acceptedTerms': acceptedTerms,
      },
    );
    return unwrapData(res.data);
  }

  @override
  Future<Map<String, dynamic>> fetchMySubscriptions({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final q = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) q['status'] = status;
    final res = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.mySubscriptionsEndpoint}',
      queryParameters: q,
    );
    return unwrapData(res.data);
  }

  @override
  Future<SubscriptionPurchaseModel> fetchPurchaseDetails(String id) async {
    final res = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.subscriptionPurchaseDetails(id)}',
    );
    return SubscriptionPurchaseModel.fromJson(unwrapData(res.data));
  }

  @override
  Future<Map<String, dynamic>> fetchUsageLogs(
    String purchaseId, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.subscriptionPurchaseUsageLogs(purchaseId)}',
      queryParameters: {'page': page, 'limit': limit},
    );
    return unwrapData(res.data);
  }
}
