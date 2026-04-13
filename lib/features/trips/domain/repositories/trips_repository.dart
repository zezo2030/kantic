import '../entities/create_trip_request_input.dart';
import '../entities/school_trip_request_entity.dart';
import '../entities/submit_trip_request_input.dart';
import '../entities/trip_participants_upload_entity.dart';
import '../entities/trip_requests_filter.dart';

abstract class TripsRepository {
  Future<String> createTripRequest(CreateTripRequestInput input);

  Future<SchoolTripRequestEntity> getTripRequest(String requestId);

  Future<List<SchoolTripRequestEntity>> getTripRequests(
    TripRequestsFilter filter,
  );

  Future<void> submitTripRequest({
    required String requestId,
    required SubmitTripRequestInput input,
  });

  Future<int> uploadParticipants({
    required String requestId,
    required TripParticipantsUploadEntity upload,
  });

  Future<List<Map<String, dynamic>>> getTripTickets(String tripRequestId);

  Future<void> cancelTripRequest({required String requestId, String? reason});

  Future<SchoolTripRequestEntity> updateTripRequest({
    required String requestId,
    required Map<String, dynamic> data,
  });
}
