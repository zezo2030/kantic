import 'package:equatable/equatable.dart';

import '../../domain/entities/school_trip_request_entity.dart';

class TripRequestDetailsState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final bool isUploading;
  final SchoolTripRequestEntity? request;
  final String? errorMessage;
  final String? successMessage;

  const TripRequestDetailsState({
    required this.isLoading,
    required this.isSubmitting,
    required this.isUploading,
    required this.request,
    this.errorMessage,
    this.successMessage,
  });

  factory TripRequestDetailsState.initial() {
    return const TripRequestDetailsState(
      isLoading: false,
      isSubmitting: false,
      isUploading: false,
      request: null,
      errorMessage: null,
      successMessage: null,
    );
  }

  TripRequestDetailsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isUploading,
    SchoolTripRequestEntity? request,
    String? errorMessage,
    String? successMessage,
  }) {
    return TripRequestDetailsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isUploading: isUploading ?? this.isUploading,
      request: request ?? this.request,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  bool get hasData => request != null;

  @override
  List<Object?> get props =>
      [isLoading, isSubmitting, isUploading, request, errorMessage, successMessage];
}

