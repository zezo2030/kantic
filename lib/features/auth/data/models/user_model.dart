import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
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
  final WalletModel? wallet;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      roles: entity.roles,
      language: entity.language,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      phone: entity.phone,
      lastLoginAt: entity.lastLoginAt,
      branchId: entity.branchId,
      wallet: entity.wallet != null
          ? WalletModel.fromEntity(entity.wallet!)
          : null,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      roles: roles,
      language: language,
      isActive: isActive,
      createdAt: createdAt,
      phone: phone,
      lastLoginAt: lastLoginAt,
      branchId: branchId,
      wallet: wallet?.toEntity(),
    );
  }
}

@JsonSerializable()
class WalletModel {
  @JsonKey(fromJson: _doubleFromJson)
  final double balance;
  @JsonKey(fromJson: _intFromJson)
  final int loyaltyPoints;
  @JsonKey(fromJson: _doubleFromJson)
  final double totalEarned;
  @JsonKey(fromJson: _doubleFromJson)
  final double totalSpent;

  const WalletModel({
    required this.balance,
    required this.loyaltyPoints,
    required this.totalEarned,
    required this.totalSpent,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) =>
      _$WalletModelFromJson(json);

  // Helper functions to handle both String and num types from API
  static double _doubleFromJson(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _intFromJson(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => _$WalletModelToJson(this);

  factory WalletModel.fromEntity(WalletEntity entity) {
    return WalletModel(
      balance: entity.balance,
      loyaltyPoints: entity.loyaltyPoints,
      totalEarned: entity.totalEarned,
      totalSpent: entity.totalSpent,
    );
  }

  WalletEntity toEntity() {
    return WalletEntity(
      balance: balance,
      loyaltyPoints: loyaltyPoints,
      totalEarned: totalEarned,
      totalSpent: totalSpent,
    );
  }
}
