// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
      language: json['language'] as String,
      isActive: json['isActive'] as bool?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      phone: json['phone'] as String?,
      lastLoginAt: json['lastLoginAt'] == null
          ? null
          : DateTime.parse(json['lastLoginAt'] as String),
      branchId: json['branchId'] as String?,
      wallet: json['wallet'] == null
          ? null
          : WalletModel.fromJson(json['wallet'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'roles': instance.roles,
      'language': instance.language,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'phone': instance.phone,
      'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
      'branchId': instance.branchId,
      'wallet': instance.wallet,
    };

WalletModel _$WalletModelFromJson(Map<String, dynamic> json) => WalletModel(
      balance: WalletModel._doubleFromJson(json['balance']),
      loyaltyPoints: WalletModel._intFromJson(json['loyaltyPoints']),
      totalEarned: WalletModel._doubleFromJson(json['totalEarned']),
      totalSpent: WalletModel._doubleFromJson(json['totalSpent']),
    );

Map<String, dynamic> _$WalletModelToJson(WalletModel instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'loyaltyPoints': instance.loyaltyPoints,
      'totalEarned': instance.totalEarned,
      'totalSpent': instance.totalSpent,
    };
