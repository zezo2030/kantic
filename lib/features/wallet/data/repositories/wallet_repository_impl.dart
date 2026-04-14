import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remote;

  WalletRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, WalletEntity>> getWalletBalance() async {
    try {
      final wallet = await remote.getWalletBalance();
      return Right(wallet.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions({
    WalletTransactionType? type,
    WalletTransactionStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final transactions = await remote.getTransactions(
        type: type,
        status: status,
        page: page,
        pageSize: pageSize,
      );
      return Right(transactions.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletRechargeResult>> rechargeWallet({
    required double amount,
  }) async {
    try {
      final response = await remote.rechargeWallet(amount: amount);

      final payment = response['payment'] as Map<String, dynamic>?;
      final result = WalletRechargeResult(
        paymentId: payment?['id'] as String? ?? response['paymentId'] as String?,
        redirectUrl: payment?['redirectUrl'] as String? ??
            response['redirectUrl'] as String?,
        chargeId: payment?['chargeId'] as String? ?? response['chargeId'] as String?,
      );

      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> confirmRechargePayment({
    required String paymentId,
    required String moyasarPaymentId,
  }) async {
    try {
      final ok = await remote.confirmRechargePayment(
        paymentId: paymentId,
        moyasarPaymentId: moyasarPaymentId,
      );
      return Right(ok);
    } catch (e) {
      return Left(
        ServerFailure(message: e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }
}
