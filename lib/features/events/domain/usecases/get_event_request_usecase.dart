// Get Event Request UseCase - Domain Layer
import '../entities/event_request_entity.dart';
import '../repositories/event_request_repository.dart';

class GetEventRequestUseCase {
  final EventRequestRepository repository;

  GetEventRequestUseCase({required this.repository});

  Future<EventRequestEntity> call(String id) async {
    return await repository.getRequest(id);
  }
}

