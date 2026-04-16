// Event Request State - Presentation Layer
import 'package:equatable/equatable.dart';
import '../../domain/entities/event_request_entity.dart';

abstract class EventRequestState extends Equatable {
  const EventRequestState();

  @override
  List<Object?> get props => [];
}

class EventRequestInitial extends EventRequestState {}

// List States
class EventRequestsLoading extends EventRequestState {}

class EventRequestsLoaded extends EventRequestState {
  final List<EventRequestEntity> requests;
  final int total;
  final int page;
  final int totalPages;

  const EventRequestsLoaded({
    required this.requests,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [requests, total, page, totalPages];
}

class EventRequestsError extends EventRequestState {
  final String message;

  const EventRequestsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Create States
class EventRequestCreating extends EventRequestState {}

class EventRequestCreated extends EventRequestState {
  final EventRequestEntity request;

  const EventRequestCreated({required this.request});

  @override
  List<Object?> get props => [request];
}

/// Emitted when the pay-first intent is ready and we can open the payment page.
class EventRequestPaymentReady extends EventRequestState {
  final String paymentId;
  final double amount;
  final String paymentMethod;
  /// Snapshot of event payload to pass to the Moyasar page so it can confirm.
  final Map<String, dynamic> eventPayload;

  const EventRequestPaymentReady({
    required this.paymentId,
    required this.amount,
    required this.paymentMethod,
    required this.eventPayload,
  });

  @override
  List<Object?> get props => [paymentId, amount, paymentMethod, eventPayload];
}

class EventRequestCreateError extends EventRequestState {
  final String message;
  /// When the API rejects create because a quoted request awaits payment for this branch.
  final String? redirectToRequestId;

  const EventRequestCreateError({
    required this.message,
    this.redirectToRequestId,
  });

  @override
  List<Object?> get props => [message, redirectToRequestId];
}

// Detail States
class EventRequestDetailLoading extends EventRequestState {}

class EventRequestDetailLoaded extends EventRequestState {
  final EventRequestEntity request;

  const EventRequestDetailLoaded({required this.request});

  @override
  List<Object?> get props => [request];
}

class EventRequestDetailError extends EventRequestState {
  final String message;

  const EventRequestDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}

