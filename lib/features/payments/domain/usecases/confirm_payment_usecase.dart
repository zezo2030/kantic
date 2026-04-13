import '../entities/payment_entities.dart';
import '../repositories/payment_repository.dart';

class ConfirmPaymentUseCase {
  final PaymentRepository repository;

  ConfirmPaymentUseCase({required this.repository});

  Future<ConfirmPaymentResultEntity> call({
    String? bookingId,
    String? eventRequestId,
    String? tripRequestId,
    String? subscriptionPurchaseId,
    String? offerBookingId,
    required String paymentId,
    String? chargeId,
  }) {
    return repository.confirm(
      bookingId: bookingId,
      eventRequestId: eventRequestId,
      tripRequestId: tripRequestId,
      subscriptionPurchaseId: subscriptionPurchaseId,
      offerBookingId: offerBookingId,
      paymentId: paymentId,
      chargeId: chargeId,
    );
  }
}
