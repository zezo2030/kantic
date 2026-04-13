// Event Request Cubit - Presentation Layer
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_event_requests_usecase.dart';
import '../../domain/usecases/create_event_request_usecase.dart';
import '../../domain/usecases/get_event_request_usecase.dart';
import '../../domain/repositories/event_request_repository.dart';
import 'event_request_state.dart';

class EventRequestCubit extends Cubit<EventRequestState> {
  final GetEventRequestsUseCase getEventRequestsUseCase;
  final CreateEventRequestUseCase createEventRequestUseCase;
  final GetEventRequestUseCase getEventRequestUseCase;
  final EventRequestRepository repository;

  EventRequestCubit({
    required this.getEventRequestsUseCase,
    required this.createEventRequestUseCase,
    required this.getEventRequestUseCase,
    required this.repository,
  }) : super(EventRequestInitial());

  Future<void> getRequests({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
  }) async {
    emit(EventRequestsLoading());

    try {
      final requests = await getEventRequestsUseCase.call(
        page: page,
        limit: limit,
        status: status,
        type: type,
      );
      
      // Get pagination info from the repository response
      // Note: This needs to be updated if repository returns pagination info
      final total = requests.length;
      final totalPages = total > 0 ? ((total - 1) ~/ limit + 1) : 1;
      
      emit(EventRequestsLoaded(
        requests: requests,
        total: total,
        page: page,
        totalPages: totalPages,
      ));
    } catch (e) {
      emit(EventRequestsError(message: e.toString()));
    }
  }

  Future<void> createRequest({
    required String type,
    required String branchId,
    String? hallId,
    required DateTime startTime,
    required int durationHours,
    required int persons,
    bool decorated = false,
    List<Map<String, dynamic>>? addOns,
    String? notes,
  }) async {
    emit(EventRequestCreating());

    try {
      final request = await createEventRequestUseCase.call(
        type: type,
        branchId: branchId,
        hallId: hallId,
        startTime: startTime,
        durationHours: durationHours,
        persons: persons,
        decorated: decorated,
        addOns: addOns,
        notes: notes,
      );

      emit(EventRequestCreated(request: request));
    } catch (e) {
      emit(EventRequestCreateError(message: e.toString()));
    }
  }

  Future<void> getRequest(String id) async {
    emit(EventRequestDetailLoading());

    try {
      final request = await getEventRequestUseCase.call(id);
      emit(EventRequestDetailLoaded(request: request));
    } catch (e) {
      emit(EventRequestDetailError(message: e.toString()));
    }
  }

  Future<List<Map<String, dynamic>>> getEventTickets(String eventRequestId) async {
    try {
      return await repository.getEventTickets(eventRequestId);
    } catch (e) {
      rethrow;
    }
  }
}

