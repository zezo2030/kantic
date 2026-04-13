import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final List<String> roles;
  final String language;
  final bool? isActive;
  final DateTime createdAt;
  final String? phone;
  final DateTime? lastLoginAt;
  final String? branchId;
  final WalletEntity? wallet;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.roles,
    required this.language,
    this.isActive,
    required this.createdAt,
    this.phone,
    this.lastLoginAt,
    this.branchId,
    this.wallet,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    roles,
    language,
    isActive,
    createdAt,
    phone,
    lastLoginAt,
    branchId,
    wallet,
  ];
}

class WalletEntity extends Equatable {
  final double balance;
  final int loyaltyPoints;
  final double totalEarned;
  final double totalSpent;

  const WalletEntity({
    required this.balance,
    required this.loyaltyPoints,
    required this.totalEarned,
    required this.totalSpent,
  });

  @override
  List<Object> get props => [balance, loyaltyPoints, totalEarned, totalSpent];
}
