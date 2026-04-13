import '../entities/trip_participants_upload_entity.dart';
import '../repositories/trips_repository.dart';

class UploadTripParticipantsUseCase {
  final TripsRepository repository;

  const UploadTripParticipantsUseCase(this.repository);

  Future<int> call({
    required String requestId,
    required TripParticipantsUploadEntity upload,
  }) {
    return repository.uploadParticipants(
      requestId: requestId,
      upload: upload,
    );
  }
}

