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

class EventRequestCreateError extends EventRequestState {
  final String message;

  const EventRequestCreateError({required this.message});

  @override
  List<Object?> get props => [message];
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

