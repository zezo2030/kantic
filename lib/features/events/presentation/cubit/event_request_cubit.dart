// Event Request Cubit - Presentation Layer
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_event_requests_usecase.dart';
import '../../domain/usecases/create_event_request_usecase.dart';
import '../../domain/usecases/get_event_request_usecase.dart';
import '../../domain/repositories/event_request_repository.dart';
import '../../../payments/di/payments_injection.dart' as payments_di;
import '../../../payments/domain/usecases/create_payment_intent_usecase.dart';
import 'event_request_state.dart';

String _messageFromCreateError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    return e.message ?? e.toString();
  }
  return e.toString();
}

bool _isQuotedAwaitingPaymentForBranch(String message) {
  final l = message.toLowerCase();
  return l.contains('complete payment') ||
      (l.contains('quoted') &&
          l.contains('this branch') &&
          l.contains('already'));
}

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
    required String selectedTimeSlot,
    required bool acceptedTerms,
    required String paymentOption,
    String? paymentMethod,
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
        selectedTimeSlot: selectedTimeSlot,
        acceptedTerms: acceptedTerms,
        paymentOption: paymentOption,
        paymentMethod: paymentMethod,
      );

      emit(EventRequestCreated(request: request));
    } catch (e) {
      final msg = _messageFromCreateError(e);
      String? redirectId;
      if (_isQuotedAwaitingPaymentForBranch(msg)) {
        try {
          final quoted = await getEventRequestsUseCase.call(
            page: 1,
            limit: 50,
            status: 'quoted',
          );
          for (final r in quoted) {
            if (r.branchId == branchId) {
              redirectId = r.id;
              break;
            }
          }
        } catch (_) {
          // Fall back to error message only
        }
      }
      emit(
        EventRequestCreateError(
          message: msg,
          redirectToRequestId: redirectId,
        ),
      );
    }
  }

  /// Pay-First flow: creates a payment intent with the event details.
  /// The [EventRequest] record is only created after successful payment.
  Future<void> initiatePayFirstRequest({
    required String type,
    required String branchId,
    required DateTime selectedDate,
    required String selectedTimeSlot,
    required int durationHours,
    required int persons,
    required String paymentOption,
    required bool acceptedTerms,
    required String paymentMethod,
    List<Map<String, dynamic>>? addOns,
    String? notes,
  }) async {
    emit(EventRequestCreating());

    try {
      payments_di.initPayments();
      final createIntent = payments_di.sl<CreatePaymentIntentUseCase>();

      final dateStr =
          '${selectedDate.year.toString().padLeft(4, '0')}-'
          '${selectedDate.month.toString().padLeft(2, '0')}-'
          '${selectedDate.day.toString().padLeft(2, '0')}';

      final eventPayload = <String, dynamic>{
        'type': type,
        'branchId': branchId,
        'startTime': dateStr,
        'selectedTimeSlot': selectedTimeSlot,
        'durationHours': durationHours,
        'persons': persons,
        'paymentOption': paymentOption,
        'acceptedTerms': acceptedTerms,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (addOns != null && addOns.isNotEmpty) 'addOns': addOns,
      };

      final intent = await createIntent(
        eventRequestPayload: eventPayload,
        acceptedTerms: acceptedTerms,
        method: paymentMethod,
      );

      emit(EventRequestPaymentReady(
        paymentId: intent.paymentId,
        amount: intent.amount ?? 0.0,
        paymentMethod: paymentMethod,
        eventPayload: eventPayload,
      ));
    } catch (e) {
      final msg = _messageFromCreateError(e);
      emit(EventRequestCreateError(message: msg));
    }
  }

  Future<Map<String, dynamic>> loadEventConfig({
    String? branchId,
    String? date,
  }) async {
    return repository.getEventConfig(branchId: branchId, date: date);
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

  /// Returns an existing [quoted] request id for this branch, if any (awaiting payment).
  Future<String?> findQuotedRequestIdForBranch(String branchId) async {
    if (branchId.isEmpty) return null;
    try {
      final quoted = await getEventRequestsUseCase.call(
        page: 1,
        limit: 50,
        status: 'quoted',
      );
      for (final r in quoted) {
        if (r.branchId == branchId) return r.id;
      }
    } catch (_) {}
    return null;
  }
}

