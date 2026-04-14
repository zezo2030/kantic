import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/wallet_repository.dart';

class RechargeWalletUseCase {
  final WalletRepository repository;

  RechargeWalletUseCase(this.repository);

  Future<Either<Failure, WalletRechargeResult>> call({
    required double amount,
  }) {
    return repository.rechargeWallet(amount: amount);
  }

  Future<Either<Failure, bool>> confirmPayment({
    required String paymentId,
    required String moyasarPaymentId,
  }) {
    return repository.confirmRechargePayment(
      paymentId: paymentId,
      moyasarPaymentId: moyasarPaymentId,
    );
  }
}
