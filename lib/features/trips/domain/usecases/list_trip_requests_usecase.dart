import '../entities/school_trip_request_entity.dart';
import '../entities/trip_requests_filter.dart';
import '../repositories/trips_repository.dart';

class ListTripRequestsUseCase {
  final TripsRepository repository;

  const ListTripRequestsUseCase(this.repository);

  Future<List<SchoolTripRequestEntity>> call(TripRequestsFilter filter) {
    return repository.getTripRequests(filter);
  }
}

