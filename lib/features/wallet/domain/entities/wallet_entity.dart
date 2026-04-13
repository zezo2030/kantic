import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final double balance;
  final String currency;
  final double totalEarned;
  final double totalSpent;

  const WalletEntity({
    required this.balance,
    this.currency = 'SAR',
    required this.totalEarned,
    required this.totalSpent,
  });

  @override
  List<Object> get props => [balance, currency, totalEarned, totalSpent];
}
