import '../../data/models/subscription_plan_model.dart';
import '../repositories/subscription_repository.dart';

class GetBranchSubscriptionPlansUseCase {
  final SubscriptionRepository repository;

  GetBranchSubscriptionPlansUseCase(this.repository);

  Future<List<SubscriptionPlanModel>> call(String branchId) =>
      repository.getPlansForBranch(branchId);
}
