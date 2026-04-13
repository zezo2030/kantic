import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/wallet_entity.dart';
import '../entities/wallet_transaction_entity.dart';

abstract class WalletRepository {
  Future<Either<Failure, WalletEntity>> getWalletBalance();
  
  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions({
    WalletTransactionType? type,
    WalletTransactionStatus? status,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, RedeemPointsResult>> redeemPoints({required int points});
}

class RedeemPointsResult {
  final int redeemed;
  final double credit;

  RedeemPointsResult({
    required this.redeemed,
    required this.credit,
  });
}
