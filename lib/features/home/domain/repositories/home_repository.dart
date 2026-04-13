import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/home_data_entity.dart';
import '../entities/branch_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, HomeDataEntity>> getHomeData();
  Future<Either<Failure, BranchEntity>> getBranchDetails(String branchId);
}
