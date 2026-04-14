import 'package:equatable/equatable.dart';

import '../../domain/entities/school_trip_request_entity.dart';

class TripRequestDetailsState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final SchoolTripRequestEntity? request;
  final String? errorMessage;
  final String? successMessage;

  const TripRequestDetailsState({
    required this.isLoading,
    required this.isSubmitting,
    required this.request,
    this.errorMessage,
    this.successMessage,
  });

  factory TripRequestDetailsState.initial() {
    return const TripRequestDetailsState(
      isLoading: false,
      isSubmitting: false,
      request: null,
      errorMessage: null,
      successMessage: null,
    );
  }

  TripRequestDetailsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    SchoolTripRequestEntity? request,
    String? errorMessage,
    String? successMessage,
  }) {
    return TripRequestDetailsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      request: request ?? this.request,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  bool get hasData => request != null;

  @override
  List<Object?> get props =>
      [isLoading, isSubmitting, request, errorMessage, successMessage];
}
