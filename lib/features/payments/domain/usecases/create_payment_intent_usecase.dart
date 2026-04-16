import '../entities/payment_entities.dart';
import '../repositories/payment_repository.dart';

class CreatePaymentIntentUseCase {
  final PaymentRepository repository;

  CreatePaymentIntentUseCase({required this.repository});

  Future<PaymentIntentEntity> call({
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
  }) {
    return repository.createIntent(
      bookingId: bookingId,
      eventRequestId: eventRequestId,
      tripRequestId: tripRequestId,
      subscriptionPurchaseId: subscriptionPurchaseId,
      subscriptionPlanId: subscriptionPlanId,
      offerBookingId: offerBookingId,
      offerProductId: offerProductId,
      acceptedTerms: acceptedTerms,
      eventRequestPayload: eventRequestPayload,
      method: method,
    );
  }
}

