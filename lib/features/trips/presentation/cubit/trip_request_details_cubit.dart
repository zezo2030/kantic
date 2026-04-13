import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/school_trip_request_entity.dart';
import '../../domain/entities/submit_trip_request_input.dart';
import '../../domain/entities/trip_participants_upload_entity.dart';
import '../../domain/repositories/trips_repository.dart';
import '../../domain/usecases/cancel_trip_request_usecase.dart';
import '../../domain/usecases/get_trip_request_usecase.dart';
import '../../domain/usecases/submit_trip_request_usecase.dart';
import '../../domain/usecases/upload_trip_participants_usecase.dart';
import 'trip_request_details_state.dart';

class TripRequestDetailsCubit extends Cubit<TripRequestDetailsState> {
  TripRequestDetailsCubit({
    required this.getTripRequestUseCase,
    required this.submitTripRequestUseCase,
    required this.uploadTripParticipantsUseCase,
    required this.cancelTripRequestUseCase,
    required this.repository,
  }) : super(TripRequestDetailsState.initial());

  final GetTripRequestUseCase getTripRequestUseCase;
  final SubmitTripRequestUseCase submitTripRequestUseCase;
  final UploadTripParticipantsUseCase uploadTripParticipantsUseCase;
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

  Future<void> submitRequest(String requestId, {String? note}) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      await submitTripRequestUseCase(
        requestId: requestId,
        input: SubmitTripRequestInput(note: note),
      );
      await load(requestId);
      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'تم إرسال الطلب للمراجعة بنجاح',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  Future<void> uploadParticipants({
    required String requestId,
    required Uint8List fileBytes,
    required String filename,
    String? contentType,
  }) async {
    emit(
      state.copyWith(
        isUploading: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      await uploadTripParticipantsUseCase(
        requestId: requestId,
        upload: TripParticipantsUploadEntity(
          bytes: fileBytes,
          filename: filename,
          contentType: contentType,
        ),
      );
      await load(requestId);
      emit(
        state.copyWith(
          isUploading: false,
          successMessage: 'تم رفع ملف الطلاب بنجاح',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isUploading: false, errorMessage: e.toString()));
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
