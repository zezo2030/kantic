import '../entities/submit_trip_request_input.dart';
import '../repositories/trips_repository.dart';

class SubmitTripRequestUseCase {
  final TripsRepository repository;

  const SubmitTripRequestUseCase(this.repository);

  Future<void> call({
    required String requestId,
    required SubmitTripRequestInput input,
  }) {
    return repository.submitTripRequest(
      requestId: requestId,
      input: input,
    );
  }
}

