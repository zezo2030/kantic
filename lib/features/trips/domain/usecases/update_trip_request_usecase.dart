import '../entities/school_trip_request_entity.dart';
import '../repositories/trips_repository.dart';

class UpdateTripRequestUseCase {
  final TripsRepository repository;

  const UpdateTripRequestUseCase(this.repository);

  Future<SchoolTripRequestEntity> call({
    required String requestId,
    required Map<String, dynamic> data,
  }) {
    return repository.updateTripRequest(requestId: requestId, data: data);
  }
}
