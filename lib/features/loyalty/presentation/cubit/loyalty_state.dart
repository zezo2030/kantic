import '../../domain/entities/loyalty_entity.dart';

abstract class LoyaltyState {}

class LoyaltyInitial extends LoyaltyState {}

class LoyaltyLoading extends LoyaltyState {}

class LoyaltyLoaded extends LoyaltyState {
  final LoyaltyInfoEntity info;

  LoyaltyLoaded(this.info);
}

class LoyaltyError extends LoyaltyState {
  final String message;

  LoyaltyError(this.message);
}

class LoyaltyRedeemLoading extends LoyaltyState {
  final LoyaltyInfoEntity info;

  LoyaltyRedeemLoading(this.info);
}

class LoyaltyRedeemSuccess extends LoyaltyState {
  final LoyaltyInfoEntity info;
  final RedeemTicketResult ticket;

  LoyaltyRedeemSuccess({required this.info, required this.ticket});
}

class LoyaltyRedeemError extends LoyaltyState {
  final LoyaltyInfoEntity info;
  final String message;

  LoyaltyRedeemError({required this.info, required this.message});
}
