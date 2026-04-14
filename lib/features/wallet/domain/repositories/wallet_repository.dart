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

  Future<Either<Failure, WalletRechargeResult>> rechargeWallet({
    required double amount,
  });

  Future<Either<Failure, bool>> confirmRechargePayment({
    required String paymentId,
    required String moyasarPaymentId,
  });
}

class WalletRechargeResult {
  final String? paymentId;
  final String? redirectUrl;
  final String? chargeId;

  WalletRechargeResult({
    this.paymentId,
    this.redirectUrl,
    this.chargeId,
  });
}
