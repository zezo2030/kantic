import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/branch_entity.dart';
import '../repositories/home_repository.dart';

class GetBranchDetailsUseCase {
  final HomeRepository repository;

  GetBranchDetailsUseCase({required this.repository});

  Future<Either<Failure, BranchEntity>> call(String branchId) async {
    return await repository.getBranchDetails(branchId);
  }
}
