import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_transaction_entity.dart';
import '../repositories/wallet_repository.dart';

class GetTransactionsUseCase {
  final WalletRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<Either<Failure, List<WalletTransactionEntity>>> call({
    WalletTransactionType? type,
    WalletTransactionStatus? status,
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.getTransactions(
      type: type,
      status: status,
      page: page,
      pageSize: pageSize,
    );
  }
}
