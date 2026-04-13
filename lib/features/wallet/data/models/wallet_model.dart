import '../../domain/entities/wallet_entity.dart';

class WalletModel {
  final double balance;
  final String currency;
  final double totalEarned;
  final double totalSpent;

  const WalletModel({
    required this.balance,
    this.currency = 'SAR',
    required this.totalEarned,
    required this.totalSpent,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return WalletModel(
      balance: toDouble(json['balance']),
      currency: json['currency'] ?? 'SAR',
      totalEarned: toDouble(json['totalEarned']),
      totalSpent: toDouble(json['totalSpent']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'currency': currency,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
    };
  }

  WalletEntity toEntity() {
    return WalletEntity(
      balance: balance,
      currency: currency,
      totalEarned: totalEarned,
      totalSpent: totalSpent,
    );
  }
}
