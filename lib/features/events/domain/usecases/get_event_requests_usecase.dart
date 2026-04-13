// Get Event Requests UseCase - Domain Layer
import '../entities/event_request_entity.dart';
import '../repositories/event_request_repository.dart';

class GetEventRequestsUseCase {
  final EventRequestRepository repository;

  GetEventRequestsUseCase({required this.repository});

  Future<List<EventRequestEntity>> call({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
  }) async {
    return await repository.getRequests(
      page: page,
      limit: limit,
      status: status,
      type: type,
    );
  }
}

