enum TripRequestStatus {
  pending('pending'),
  underReview('under_review'),
  approved('approved'),
  depositPaid('deposit_paid'),
  rejected('rejected'),
  invoiced('invoiced'),
  paid('paid'),
  completed('completed'),
  cancelled('cancelled'),
  unknown('unknown');

  final String apiValue;

  const TripRequestStatus(this.apiValue);

  bool get isTerminal =>
      this == TripRequestStatus.completed || this == TripRequestStatus.cancelled;

  static TripRequestStatus fromApi(String? value) {
    if (value == null) return TripRequestStatus.unknown;
    final normalized = value.toLowerCase();
    // Some trip payment responses use this label; persisted status is usually `paid`.
    if (normalized == 'paid_and_completed') {
      return TripRequestStatus.paid;
    }
    for (final status in TripRequestStatus.values) {
      if (status.apiValue == normalized) return status;
    }
    return TripRequestStatus.unknown;
  }
}

