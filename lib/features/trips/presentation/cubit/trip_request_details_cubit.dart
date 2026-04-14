import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/school_trip_request_entity.dart';
import '../../domain/repositories/trips_repository.dart';
import '../../domain/usecases/cancel_trip_request_usecase.dart';
import '../../domain/usecases/get_trip_request_usecase.dart';
import 'trip_request_details_state.dart';

class TripRequestDetailsCubit extends Cubit<TripRequestDetailsState> {
  TripRequestDetailsCubit({
    required this.getTripRequestUseCase,
    required this.cancelTripRequestUseCase,
    required this.repository,
  }) : super(TripRequestDetailsState.initial());

  final GetTripRequestUseCase getTripRequestUseCase;
  final CancelTripRequestUseCase cancelTripRequestUseCase;
  final TripsRepository repository;

  Future<void> load(
    String requestId, {
    SchoolTripRequestEntity? optimisticRequest,
  }) async {
    if (optimisticRequest != null) {
      emit(
        state.copyWith(
          request: optimisticRequest,
          isLoading: true,
          errorMessage: null,
          successMessage: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isLoading: true,
          errorMessage: null,
          successMessage: null,
        ),
      );
    }

    try {
      final data = await getTripRequestUseCase(requestId);
      emit(state.copyWith(isLoading: false, request: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> cancelRequest(String requestId, {String? reason}) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      await cancelTripRequestUseCase(requestId: requestId, reason: reason);
      await load(requestId);
      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'تم إلغاء الطلب بنجاح',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  Future<List<Map<String, dynamic>>> getTripTickets(
    String tripRequestId,
  ) async {
    try {
      return await repository.getTripTickets(tripRequestId);
    } catch (e) {
      rethrow;
    }
  }
}
