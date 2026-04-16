import '../entities/payment_entities.dart';

abstract class PaymentRepository {
  Future<PaymentIntentEntity> createIntent({
    String? bookingId,
    String? eventRequestId,
    String? tripRequestId,
    String? subscriptionPurchaseId,
    String? subscriptionPlanId,
    String? offerBookingId,
    String? offerProductId,
    bool? acceptedTerms,
    Map<String, dynamic>? eventRequestPayload,
    required String method,
  });

  Future<ConfirmPaymentResultEntity> confirm({
    String? bookingId,
    String? eventRequestId,
    String? tripRequestId,
    String? subscriptionPurchaseId,
    String? offerBookingId,
    required String paymentId,
    String? chargeId,
  });
}
