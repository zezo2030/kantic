// Payment data models and requests
class CreatePaymentIntentRequestModel {
  final String? bookingId;
  final String? eventRequestId;
  final String? tripRequestId;
  final String? subscriptionPurchaseId;
  final String? subscriptionPlanId;
  final String? offerBookingId;
  final String? offerProductId;
  final bool? acceptedTerms;
  final String method; // credit_card / wallet

  CreatePaymentIntentRequestModel({
    this.bookingId,
    this.eventRequestId,
    this.tripRequestId,
    this.subscriptionPurchaseId,
    this.subscriptionPlanId,
    this.offerBookingId,
    this.offerProductId,
    this.acceptedTerms,
    required this.method,
  });

  Map<String, dynamic> toJson() => {
    if (bookingId != null && bookingId!.isNotEmpty) 'bookingId': bookingId,
    if (eventRequestId != null && eventRequestId!.isNotEmpty)
      'eventRequestId': eventRequestId,
    if (tripRequestId != null && tripRequestId!.isNotEmpty)
      'tripRequestId': tripRequestId,
    if (subscriptionPurchaseId != null &&
        subscriptionPurchaseId!.isNotEmpty)
      'subscriptionPurchaseId': subscriptionPurchaseId,
    if (subscriptionPlanId != null && subscriptionPlanId!.isNotEmpty)
      'subscriptionPlanId': subscriptionPlanId,
    if (offerBookingId != null && offerBookingId!.isNotEmpty)
      'offerBookingId': offerBookingId,
    if (offerProductId != null && offerProductId!.isNotEmpty)
      'offerProductId': offerProductId,
    if (acceptedTerms != null) 'acceptedTerms': acceptedTerms,
    'method': method,
  };
}

class PaymentIntentResponseModel {
  final String paymentId;
  final String chargeId;
  final String? redirectUrl;

  PaymentIntentResponseModel({
    required this.paymentId,
    required this.chargeId,
    this.redirectUrl,
  });

  factory PaymentIntentResponseModel.fromJson(Map<String, dynamic> json) {
    // API may wrap data with { data: {...} }
    final Map<String, dynamic> data = json['data'] is Map<String, dynamic>
        ? json['data']
        : json;
    return PaymentIntentResponseModel(
      paymentId: data['paymentId']?.toString() ?? data['id']?.toString() ?? '',
      chargeId:
          data['chargeId']?.toString() ?? data['gatewayRef']?.toString() ?? '',
      redirectUrl:
          data['redirectUrl']?.toString() ??
          data['redirect_url']?.toString() ??
          data['url']?.toString(),
    );
  }
}

class ConfirmPaymentRequestModel {
  final String? bookingId;
  final String? eventRequestId;
  final String? tripRequestId;
  final String? subscriptionPurchaseId;
  final String? offerBookingId;
  final String paymentId;
  final String? chargeId;

  ConfirmPaymentRequestModel({
    this.bookingId,
    this.eventRequestId,
    this.tripRequestId,
    this.subscriptionPurchaseId,
    this.offerBookingId,
    required this.paymentId,
    this.chargeId,
  });

  Map<String, dynamic> toJson() => {
    if (bookingId != null && bookingId!.isNotEmpty) 'bookingId': bookingId,
    if (eventRequestId != null && eventRequestId!.isNotEmpty)
      'eventRequestId': eventRequestId,
    if (tripRequestId != null && tripRequestId!.isNotEmpty)
      'tripRequestId': tripRequestId,
    if (subscriptionPurchaseId != null &&
        subscriptionPurchaseId!.isNotEmpty)
      'subscriptionPurchaseId': subscriptionPurchaseId,
    if (offerBookingId != null && offerBookingId!.isNotEmpty)
      'offerBookingId': offerBookingId,
    'paymentId': paymentId,
    // backend لا يعتمد على payload الآن؛ نرسل chargeId اختيارياً
    if (chargeId != null) 'gatewayPayload': {'chargeId': chargeId},
  };
}

class ConfirmPaymentResponseModel {
  final bool success;
  final String? transactionId;
  final DateTime? paidAt;

  ConfirmPaymentResponseModel({
    required this.success,
    this.transactionId,
    this.paidAt,
  });

  factory ConfirmPaymentResponseModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['data'] is Map<String, dynamic>
        ? json['data']
        : json;
    return ConfirmPaymentResponseModel(
      success: data['success'] == true,
      transactionId: data['transactionId']?.toString(),
      paidAt: data['paidAt'] != null
          ? DateTime.tryParse(data['paidAt'].toString())
          : null,
    );
  }
}
