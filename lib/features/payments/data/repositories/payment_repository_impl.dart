import '../../domain/entities/payment_entities.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';
import '../models/payment_models.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remote;

  PaymentRepositoryImpl({required this.remote});

  @override
  Future<PaymentIntentEntity> createIntent({
    String? bookingId,
    String? eventRequestId,
    String? tripRequestId,
    String? subscriptionPurchaseId,
    String? subscriptionPlanId,
    String? offerBookingId,
    String? offerProductId,
    bool? acceptedTerms,
    required String method,
  }) async {
    final normalizedBookingId =
        (bookingId != null && bookingId.trim().isNotEmpty)
        ? bookingId.trim()
        : null;
    final normalizedEventRequestId =
        (eventRequestId != null && eventRequestId.trim().isNotEmpty)
        ? eventRequestId.trim()
        : null;
    final normalizedTripRequestId =
        (tripRequestId != null && tripRequestId.trim().isNotEmpty)
        ? tripRequestId.trim()
        : null;
    final normalizedSubPurchase =
        (subscriptionPurchaseId != null &&
            subscriptionPurchaseId.trim().isNotEmpty)
        ? subscriptionPurchaseId.trim()
        : null;
    final normalizedSubPlan =
        (subscriptionPlanId != null && subscriptionPlanId.trim().isNotEmpty)
        ? subscriptionPlanId.trim()
        : null;
    final normalizedOfferBooking =
        (offerBookingId != null && offerBookingId.trim().isNotEmpty)
        ? offerBookingId.trim()
        : null;
    final normalizedOfferProduct =
        (offerProductId != null && offerProductId.trim().isNotEmpty)
        ? offerProductId.trim()
        : null;

    if (normalizedBookingId == null &&
        normalizedEventRequestId == null &&
        normalizedTripRequestId == null &&
        normalizedSubPurchase == null &&
        normalizedSubPlan == null &&
        normalizedOfferBooking == null &&
        normalizedOfferProduct == null) {
      throw ArgumentError(
        'At least one payment context id is required',
      );
    }

    final req = CreatePaymentIntentRequestModel(
      bookingId: normalizedBookingId,
      eventRequestId: normalizedEventRequestId,
      tripRequestId: normalizedTripRequestId,
      subscriptionPurchaseId: normalizedSubPurchase,
      subscriptionPlanId: normalizedSubPlan,
      offerBookingId: normalizedOfferBooking,
      offerProductId: normalizedOfferProduct,
      acceptedTerms: acceptedTerms,
      method: method,
    );

    final res = await remote.createPaymentIntent(req);
    return PaymentIntentEntity(
      paymentId: res.paymentId,
      chargeId: res.chargeId,
      method: method,
      redirectUrl: res.redirectUrl,
      amount: res.amount,
    );
  }

  @override
  Future<ConfirmPaymentResultEntity> confirm({
    String? bookingId,
    String? eventRequestId,
    String? tripRequestId,
    String? subscriptionPurchaseId,
    String? offerBookingId,
    required String paymentId,
    String? chargeId,
  }) async {
    final normalizedBookingId =
        (bookingId != null && bookingId.trim().isNotEmpty)
        ? bookingId.trim()
        : null;
    final normalizedEventRequestId =
        (eventRequestId != null && eventRequestId.trim().isNotEmpty)
        ? eventRequestId.trim()
        : null;
    final normalizedTripRequestId =
        (tripRequestId != null && tripRequestId.trim().isNotEmpty)
        ? tripRequestId.trim()
        : null;
    final normalizedSubPurchase =
        (subscriptionPurchaseId != null &&
            subscriptionPurchaseId.trim().isNotEmpty)
        ? subscriptionPurchaseId.trim()
        : null;
    final normalizedOfferBooking =
        (offerBookingId != null && offerBookingId.trim().isNotEmpty)
        ? offerBookingId.trim()
        : null;
    if (normalizedBookingId == null &&
        normalizedEventRequestId == null &&
        normalizedTripRequestId == null &&
        normalizedSubPurchase == null &&
        normalizedOfferBooking == null) {
      throw ArgumentError(
        'At least one payment context id is required for confirm',
      );
    }

    final req = ConfirmPaymentRequestModel(
      bookingId: normalizedBookingId,
      eventRequestId: normalizedEventRequestId,
      tripRequestId: normalizedTripRequestId,
      subscriptionPurchaseId: normalizedSubPurchase,
      offerBookingId: normalizedOfferBooking,
      paymentId: paymentId,
      chargeId: chargeId,
    );
    final res = await remote.confirmPayment(req);
    return ConfirmPaymentResultEntity(
      success: res.success,
      transactionId: res.transactionId,
      paidAt: res.paidAt,
    );
  }
}
