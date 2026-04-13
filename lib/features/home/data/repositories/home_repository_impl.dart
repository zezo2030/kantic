import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/home_data_entity.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, HomeDataEntity>> getHomeData() async {
    try {
      final homeResponseModel = await remoteDataSource.getHomeData();
      return Right(homeResponseModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BranchEntity>> getBranchDetails(String branchId) async {
    try {
      final branchModel = await remoteDataSource.getBranchDetails(branchId);
      return Right(branchModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

}
