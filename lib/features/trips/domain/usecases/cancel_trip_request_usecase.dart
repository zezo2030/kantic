import '../repositories/trips_repository.dart';

class CancelTripRequestUseCase {
  final TripsRepository repository;

  const CancelTripRequestUseCase(this.repository);

  Future<void> call({required String requestId, String? reason}) {
    return repository.cancelTripRequest(requestId: requestId, reason: reason);
  }
}
