// Booking State - Presentation Layer
import 'package:equatable/equatable.dart';
import '../../domain/entities/quote_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/hall_slots_entity.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingSuccess extends BookingState {}

class BookingSuccessWithData extends BookingState {
  final BookingEntity booking;
  final QuoteEntity? quote;

  const BookingSuccessWithData({required this.booking, this.quote});

  @override
  List<Object?> get props => [booking, quote];
}

class BookingError extends BookingState {
  final String message;

  const BookingError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Quote States
class QuoteLoading extends BookingState {}

class QuoteLoaded extends BookingState {
  final QuoteEntity quote;

  const QuoteLoaded({required this.quote});

  @override
  List<Object?> get props => [quote];
}

class QuoteError extends BookingState {
  final String message;

  const QuoteError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Availability States
class AvailabilityChecking extends BookingState {}

class AvailabilityChecked extends BookingState {
  final bool isAvailable;

  const AvailabilityChecked({required this.isAvailable});

  @override
  List<Object?> get props => [isAvailable];
}

class AvailabilityError extends BookingState {
  final String message;

  const AvailabilityError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Server Health States
class ServerHealthChecking extends BookingState {}

class ServerHealthChecked extends BookingState {
  final bool isHealthy;

  const ServerHealthChecked({required this.isHealthy});

  @override
  List<Object?> get props => [isHealthy];
}

class ServerHealthError extends BookingState {
  final String message;

  const ServerHealthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Slots States
class SlotsLoading extends BookingState {}

class SlotsLoaded extends BookingState {
  final BranchSlotsEntity branchSlots;

  const SlotsLoaded({required this.branchSlots});

  @override
  List<Object?> get props => [branchSlots];
}

class SlotsError extends BookingState {
  final String message;

  const SlotsError({required this.message});

  @override
  List<Object?> get props => [message];
}
