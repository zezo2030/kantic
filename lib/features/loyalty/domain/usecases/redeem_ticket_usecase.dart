import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/loyalty_entity.dart';
import '../repositories/loyalty_repository.dart';

class RedeemTicketUseCase {
  final LoyaltyRepository repository;

  RedeemTicketUseCase(this.repository);

  Future<Either<Failure, RedeemTicketResult>> call({
    required String branchId,
  }) {
    return repository.redeemTicket(branchId: branchId);
  }
}
