import '../entities/create_trip_request_input.dart';
import '../repositories/trips_repository.dart';

class CreateTripRequestUseCase {
  final TripsRepository repository;

  const CreateTripRequestUseCase(this.repository);

  Future<String> call(CreateTripRequestInput input) {
    return repository.createTripRequest(input);
  }
}

