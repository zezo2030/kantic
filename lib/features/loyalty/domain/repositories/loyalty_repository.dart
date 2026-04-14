import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/loyalty_entity.dart';

abstract class LoyaltyRepository {
  Future<Either<Failure, LoyaltyInfoEntity>> getLoyaltyInfo();
  Future<Either<Failure, RedeemTicketResult>> redeemTicket({
    required String branchId,
  });
}
