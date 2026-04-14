import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_requests_filter.dart';
import '../../domain/usecases/list_trip_requests_usecase.dart';
import 'trip_requests_state.dart';

class TripRequestsCubit extends Cubit<TripRequestsState> {
  TripRequestsCubit({required this.listTripRequestsUseCase})
      : super(TripRequestsState.initial());

  final ListTripRequestsUseCase listTripRequestsUseCase;

  Future<void> load({bool forceRefresh = true}) async {
    const filter = TripRequestsFilter(page: 1, limit: 50);

    if (!forceRefresh && state.requests.isNotEmpty) {
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

  void setPreferredDateFilter(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    emit(state.copyWith(dateFilter: d));
  }

  void clearPreferredDateFilter() {
    emit(state.copyWith(clearDateFilter: true));
  }
}

