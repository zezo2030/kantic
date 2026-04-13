import '../../domain/entities/wallet_transaction_entity.dart';

class WalletTransactionModel {
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

  const WalletTransactionModel({
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

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    WalletTransactionType type;
    switch (json['type']) {
      case 'deposit':
        type = WalletTransactionType.deposit;
        break;
      case 'withdrawal':
        type = WalletTransactionType.withdrawal;
        break;
      default:
        type = WalletTransactionType.deposit;
    }

    WalletTransactionStatus status;
    switch (json['status']) {
      case 'success':
        status = WalletTransactionStatus.success;
        break;
      case 'failed':
        status = WalletTransactionStatus.failed;
        break;
      default:
        status = WalletTransactionStatus.success;
    }

    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return WalletTransactionModel(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      userId: json['userId'] as String,
      type: type,
      amount: toDouble(json['amount']),
      method: json['method'] as String?,
      status: status,
      reference: json['reference'] as String?,
      relatedBookingId: json['relatedBookingId'] as String?,
      failureReason: json['failureReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'userId': userId,
      'type': type == WalletTransactionType.deposit ? 'deposit' : 'withdrawal',
      'amount': amount,
      'method': method,
      'status': status == WalletTransactionStatus.success
          ? 'success'
          : 'failed',
      'reference': reference,
      'relatedBookingId': relatedBookingId,
      'failureReason': failureReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  WalletTransactionEntity toEntity() {
    return WalletTransactionEntity(
      id: id,
      walletId: walletId,
      userId: userId,
      type: type,
      amount: amount,
      method: method,
      status: status,
      reference: reference,
      relatedBookingId: relatedBookingId,
      failureReason: failureReason,
      createdAt: createdAt,
    );
  }
}
