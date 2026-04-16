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
  final Map<String, dynamic>? eventRequestPayload;
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
    this.eventRequestPayload,
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
    if (eventRequestPayload != null && eventRequestPayload!.isNotEmpty)
      'eventRequestPayload': eventRequestPayload,
    'method': method,
  };
}

class PaymentIntentResponseModel {
  final String paymentId;
  final String chargeId;
  final String? redirectUrl;
  /// Payable amount in major units (e.g. SAR), from backend — must match Moyasar charge for confirm.
  final double? amount;

  PaymentIntentResponseModel({
    required this.paymentId,
    required this.chargeId,
    this.redirectUrl,
    this.amount,
  });

  static double? _parseAmount(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory PaymentIntentResponseModel.fromJson(Map<String, dynamic> json) {
    // API may wrap data with { data: {...} }
    final Map<String, dynamic> data = json['data'] is Map<String, dynamic>
        ? json['data']
        : json;
    return PaymentIntentResponseModel(
      paymentId: data['paymentId']?.toString() ?? data['id']?.toString() ?? '',
      chargeId: data['chargeId']?.toString() ??
          data['gatewayRef']?.toString() ??
          data['clientSecret']?.toString() ??
          '',
      redirectUrl:
          data['redirectUrl']?.toString() ??
          data['redirect_url']?.toString() ??
          data['url']?.toString(),
      amount: _parseAmount(data['amount']),
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
    if (chargeId != null && chargeId!.trim().isNotEmpty)
      'gatewayPayload': {
        'moyasarPaymentId': chargeId,
        'paymentId': chargeId,
      },
  };
}

class ConfirmPaymentResponseModel {
  final bool success;
  final String? transactionId;
  final DateTime? paidAt;
  /// Returned by the backend when the pay-first event request flow completes.
  final String? eventRequestId;

  ConfirmPaymentResponseModel({
    required this.success,
    this.transactionId,
    this.paidAt,
    this.eventRequestId,
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
      eventRequestId: data['eventRequestId']?.toString(),
    );
  }
}

