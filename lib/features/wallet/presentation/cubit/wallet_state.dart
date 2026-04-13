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

class WalletRedeemLoading extends WalletState {
  final WalletEntity? wallet;
  final List<WalletTransactionEntity> transactions;

  WalletRedeemLoading({
    this.wallet,
    this.transactions = const [],
  });
}

class WalletRedeemSuccess extends WalletState {
  final WalletEntity? wallet;
  final List<WalletTransactionEntity> transactions;
  final int redeemedPoints;
  final double creditedAmount;

  WalletRedeemSuccess({
    this.wallet,
    this.transactions = const [],
    required this.redeemedPoints,
    required this.creditedAmount,
  });
}

class WalletRedeemFailed extends WalletState {
  final WalletEntity? wallet;
  final List<WalletTransactionEntity> transactions;
  final String error;

  WalletRedeemFailed({
    this.wallet,
    this.transactions = const [],
    required this.error,
  });
}

class WalletError extends WalletState {
  final String message;

  WalletError(this.message);
}
