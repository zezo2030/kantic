import 'package:equatable/equatable.dart';

import '../../domain/entities/school_trip_request_entity.dart';
import '../../domain/entities/trip_requests_filter.dart';

class TripRequestsState extends Equatable {
  final bool isLoading;
  final List<SchoolTripRequestEntity> requests;
  final TripRequestsFilter filter;
  /// Filters the loaded list by trip preferred date (calendar day).
  final DateTime? dateFilter;
  final String? errorMessage;

  const TripRequestsState({
    required this.isLoading,
    required this.requests,
    required this.filter,
    this.dateFilter,
    this.errorMessage,
  });

  factory TripRequestsState.initial() {
    return TripRequestsState(
      isLoading: false,
      requests: const [],
      filter: const TripRequestsFilter(),
      dateFilter: null,
      errorMessage: null,
    );
  }

  List<SchoolTripRequestEntity> get visibleRequests {
    final d = dateFilter;
    if (d == null) return requests;
    return requests.where((r) => _sameCalendarDay(r.preferredDate, d)).toList();
  }

  static bool _sameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  TripRequestsState copyWith({
    bool? isLoading,
    List<SchoolTripRequestEntity>? requests,
    TripRequestsFilter? filter,
    String? errorMessage,
    DateTime? dateFilter,
    bool clearDateFilter = false,
  }) {
    return TripRequestsState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      filter: filter ?? this.filter,
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
      errorMessage: errorMessage,
    );
  }

  bool get hasError => errorMessage != null;

  bool get hasRequests => requests.isNotEmpty;

  @override
  List<Object?> get props => [isLoading, requests, filter, dateFilter, errorMessage];
}

