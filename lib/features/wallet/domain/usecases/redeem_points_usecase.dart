import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/wallet_repository.dart';

class RedeemPointsUseCase {
  final WalletRepository repository;

  RedeemPointsUseCase(this.repository);

  Future<Either<Failure, RedeemPointsResult>> call({required int points}) {
    return repository.redeemPoints(points: points);
  }
}


