// Payment domain entities
import 'package:equatable/equatable.dart';

class PaymentIntentEntity extends Equatable {
  final String paymentId;
  final String chargeId;
  final String method; // e.g., CREDIT_CARD
  final String? redirectUrl;

  const PaymentIntentEntity({
    required this.paymentId,
    required this.chargeId,
    required this.method,
    this.redirectUrl,
  });

  @override
  List<Object?> get props => [paymentId, chargeId, method, redirectUrl];
}

class ConfirmPaymentResultEntity extends Equatable {
  final bool success;
  final String? transactionId;
  final DateTime? paidAt;

  const ConfirmPaymentResultEntity({
    required this.success,
    this.transactionId,
    this.paidAt,
  });

  @override
  List<Object?> get props => [success, transactionId, paidAt];
}
