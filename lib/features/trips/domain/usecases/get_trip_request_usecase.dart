import '../entities/school_trip_request_entity.dart';
import '../repositories/trips_repository.dart';

class GetTripRequestUseCase {
  final TripsRepository repository;

  const GetTripRequestUseCase(this.repository);

  Future<SchoolTripRequestEntity> call(String requestId) {
    return repository.getTripRequest(requestId);
  }
}

