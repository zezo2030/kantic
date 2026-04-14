import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/wallet_transaction_entity.dart';

abstract class WalletState {}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final WalletEntity wallet;
  final List<WalletTransactionEntity> transactions;
  final bool isLoadingTransactions;
  final bool hasMoreTransactions;

  WalletLoaded({
    required this.wallet,
    this.transactions = const [],
    this.isLoadingTransactions = false,
    this.hasMoreTransactions = false,
  });
}

class WalletRechargeLoading extends WalletState {
  final WalletEntity? wallet;
  final List<WalletTransactionEntity> transactions;

  WalletRechargeLoading({
    this.wallet,
    this.transactions = const [],
  });
}

class WalletRechargeSuccess extends WalletState {
  final WalletEntity? wallet;
  final List<WalletTransactionEntity> transactions;
  final String? redirectUrl;
  final String? paymentId;
  final double? amount;

  WalletRechargeSuccess({
    this.wallet,
    this.transactions = const [],
    this.redirectUrl,
    this.paymentId,
    this.amount,
  });
}

class WalletRechargeFailed extends WalletState {
  final WalletEntity? wallet;
  final List<WalletTransactionEntity> transactions;
  final String error;

  WalletRechargeFailed({
    this.wallet,
    this.transactions = const [],
    required this.error,
  });
}

class WalletError extends WalletState {
  final String message;

  WalletError(this.message);
}
