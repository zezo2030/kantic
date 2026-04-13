import 'package:equatable/equatable.dart';

import '../../domain/entities/school_trip_request_entity.dart';
import '../../domain/entities/trip_request_status.dart';
import '../../domain/entities/trip_requests_filter.dart';

class TripRequestsState extends Equatable {
  final bool isLoading;
  final List<SchoolTripRequestEntity> requests;
  final TripRequestsFilter filter;
  final String? errorMessage;

  const TripRequestsState({
    required this.isLoading,
    required this.requests,
    required this.filter,
    this.errorMessage,
  });

  factory TripRequestsState.initial() {
    return TripRequestsState(
      isLoading: false,
      requests: const [],
      filter: const TripRequestsFilter(),
      errorMessage: null,
    );
  }

  TripRequestsState copyWith({
    bool? isLoading,
    List<SchoolTripRequestEntity>? requests,
    TripRequestsFilter? filter,
    String? errorMessage,
  }) {
    return TripRequestsState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }

  bool get hasError => errorMessage != null;

  bool get hasRequests => requests.isNotEmpty;

  TripRequestStatus? get statusFilter => filter.status;

  @override
  List<Object?> get props => [isLoading, requests, filter, errorMessage];
}

