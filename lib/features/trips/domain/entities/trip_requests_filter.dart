import 'trip_request_status.dart';

class TripRequestsFilter {
  final int page;
  final int limit;
  final TripRequestStatus? status;

  const TripRequestsFilter({
    this.page = 1,
    this.limit = 20,
    this.status,
  });
}

