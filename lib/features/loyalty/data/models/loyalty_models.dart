import '../../domain/entities/loyalty_entity.dart';

class LoyaltyTransactionModel {
  final String id;
  final String type;
  final int points;
  final double? amountChange;
  final String? note;
  final DateTime createdAt;

  const LoyaltyTransactionModel({
    required this.id,
    required this.type,
    required this.points,
    this.amountChange,
    this.note,
    required this.createdAt,
  });

  factory LoyaltyTransactionModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    double? toDoubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return LoyaltyTransactionModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      points: toInt(json['points']),
      amountChange: toDoubleOrNull(json['amountChange']),
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  LoyaltyTransactionEntity toEntity() {
    LoyaltyTransactionType txType;
    switch (type.toLowerCase()) {
      case 'earn':
        txType = LoyaltyTransactionType.earn;
        break;
      case 'burn':
        txType = LoyaltyTransactionType.burn;
        break;
      case 'redeem_ticket':
        txType = LoyaltyTransactionType.redeemTicket;
        break;
      case 'refund':
        txType = LoyaltyTransactionType.refund;
        break;
      case 'bonus':
        txType = LoyaltyTransactionType.bonus;
        break;
      case 'penalty':
        txType = LoyaltyTransactionType.penalty;
        break;
      default:
        txType = LoyaltyTransactionType.unknown;
    }

    return LoyaltyTransactionEntity(
      id: id,
      type: txType,
      points: points,
      amountChange: amountChange,
      note: note,
      createdAt: createdAt,
    );
  }
}

class LoyaltyInfoModel {
  final int points;
  final int pointsPerTicket;
  final List<LoyaltyTransactionModel> transactions;

  const LoyaltyInfoModel({
    required this.points,
    required this.pointsPerTicket,
    required this.transactions,
  });

  factory LoyaltyInfoModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final rawTxs = json['transactions'] as List<dynamic>? ?? [];
    final transactions = rawTxs
        .map(
          (e) =>
              LoyaltyTransactionModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();

    return LoyaltyInfoModel(
      points: toInt(json['points'] ?? json['loyaltyPoints']),
      pointsPerTicket: toInt(json['pointsPerTicket'], 500),
      transactions: transactions,
    );
  }

  LoyaltyInfoEntity toEntity() {
    return LoyaltyInfoEntity(
      points: points,
      pointsPerTicket: pointsPerTicket,
      transactions: transactions.map((t) => t.toEntity()).toList(),
    );
  }
}
