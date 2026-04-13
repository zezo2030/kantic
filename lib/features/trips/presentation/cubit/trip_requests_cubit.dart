import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_request_status.dart';
import '../../domain/entities/trip_requests_filter.dart';
import '../../domain/usecases/list_trip_requests_usecase.dart';
import 'trip_requests_state.dart';

class TripRequestsCubit extends Cubit<TripRequestsState> {
  TripRequestsCubit({required this.listTripRequestsUseCase})
      : super(TripRequestsState.initial());

  final ListTripRequestsUseCase listTripRequestsUseCase;

  Future<void> load({TripRequestStatus? status, bool forceRefresh = true}) async {
    final targetStatus = status ?? state.filter.status;
    final filter = TripRequestsFilter(
      page: 1,
      limit: 50,
      status: targetStatus,
    );

    if (!forceRefresh &&
        state.requests.isNotEmpty &&
        state.filter.status == targetStatus) {
      return;
    }

    emit(state.copyWith(isLoading: true, filter: filter, errorMessage: null));

    try {
      final items = await listTripRequestsUseCase(filter);
      emit(
        state.copyWith(
          isLoading: false,
          requests: items,
          filter: filter,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}

