import 'package:equatable/equatable.dart';

enum LoyaltyTransactionType {
  earn,
  burn,
  redeemTicket,
  refund,
  bonus,
  penalty,
  unknown,
}

class LoyaltyTransactionEntity extends Equatable {
  final String id;
  final LoyaltyTransactionType type;
  final int points;
  final double? amountChange;
  final String? note;
  final DateTime createdAt;

  const LoyaltyTransactionEntity({
    required this.id,
    required this.type,
    required this.points,
    this.amountChange,
    this.note,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, points, amountChange, note, createdAt];
}

class LoyaltyInfoEntity extends Equatable {
  final int points;
  final int pointsPerTicket;
  final List<LoyaltyTransactionEntity> transactions;

  const LoyaltyInfoEntity({
    required this.points,
    required this.pointsPerTicket,
    required this.transactions,
  });

  bool get canRedeem => points >= pointsPerTicket;

  @override
  List<Object> get props => [points, pointsPerTicket, transactions];
}

class RedeemTicketResult extends Equatable {
  final String bookingId;
  final String? qrCode;
  final String? ticketId;

  const RedeemTicketResult({
    required this.bookingId,
    this.qrCode,
    this.ticketId,
  });

  @override
  List<Object?> get props => [bookingId, qrCode, ticketId];
}
