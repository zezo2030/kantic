enum TripRequestStatus {
  pending('pending'),
  underReview('under_review'),
  approved('approved'),
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
    for (final status in TripRequestStatus.values) {
      if (status.apiValue == value) return status;
    }
    return TripRequestStatus.unknown;
  }
}

