import 'package:equatable/equatable.dart';

enum WalletTransactionType {
  deposit,
  withdrawal,
}

enum WalletTransactionStatus {
  success,
  failed,
}

class WalletTransactionEntity extends Equatable {
  final String id;
  final String walletId;
  final String userId;
  final WalletTransactionType type;
  final double amount;
  final String? method;
  final WalletTransactionStatus status;
  final String? reference;
  final String? relatedBookingId;
  final String? failureReason;
  final DateTime createdAt;

  const WalletTransactionEntity({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    this.method,
    required this.status,
    this.reference,
    this.relatedBookingId,
    this.failureReason,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        walletId,
        userId,
        type,
        amount,
        method,
        status,
        reference,
        relatedBookingId,
        failureReason,
        createdAt,
      ];
}
