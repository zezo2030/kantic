import '../../home/domain/entities/branch_entity.dart';
import '../../home/data/models/branch_model.dart';
import 'branches_api.dart';

abstract class BranchesRepository {
  Future<List<BranchEntity>> getAllBranches({bool includeInactive});
}

class BranchesRepositoryImpl implements BranchesRepository {
  final BranchesApi api;

  BranchesRepositoryImpl({required this.api});

  @override
  Future<List<BranchEntity>> getAllBranches({
    bool includeInactive = false,
  }) async {
    final List<BranchModel> models = await api.fetchAllBranches(
      includeInactive: includeInactive,
    );
    return models.map((m) => m.toEntity()).toList();
  }
}
