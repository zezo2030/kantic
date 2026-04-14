import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/loyalty_entity.dart';
import '../repositories/loyalty_repository.dart';

class GetLoyaltyInfoUseCase {
  final LoyaltyRepository repository;

  GetLoyaltyInfoUseCase(this.repository);

  Future<Either<Failure, LoyaltyInfoEntity>> call() {
    return repository.getLoyaltyInfo();
  }
}
