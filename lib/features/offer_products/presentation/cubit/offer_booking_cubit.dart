import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_offer_booking_usecase.dart';
import '../../domain/usecases/get_offer_quote_usecase.dart';

abstract class OfferBookingFlowState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OfferBookingFlowInitial extends OfferBookingFlowState {}

class OfferBookingFlowLoading extends OfferBookingFlowState {}

class OfferBookingFlowQuoteReady extends OfferBookingFlowState {
  final Map<String, dynamic> quote;

  OfferBookingFlowQuoteReady(this.quote);

  @override
  List<Object?> get props => [quote];
}

class OfferBookingFlowCreated extends OfferBookingFlowState {
  final Map<String, dynamic> result;

  OfferBookingFlowCreated(this.result);

  @override
  List<Object?> get props => [result];
}

class OfferBookingFlowError extends OfferBookingFlowState {
  final String message;

  OfferBookingFlowError(this.message);

  @override
  List<Object?> get props => [message];
}

class OfferBookingFlowConflict extends OfferBookingFlowState {
  final String message;

  OfferBookingFlowConflict(this.message);

  @override
  List<Object?> get props => [message];
}

class OfferBookingCubit extends Cubit<OfferBookingFlowState> {
  final GetOfferQuoteUseCase quoteUseCase;
  final CreateOfferBookingUseCase createUseCase;

  OfferBookingCubit({
    required this.quoteUseCase,
    required this.createUseCase,
  }) : super(OfferBookingFlowInitial());

  Future<void> fetchQuote({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
  }) async {
    emit(OfferBookingFlowLoading());
    try {
      final q = await quoteUseCase(
        offerProductId: offerProductId,
        addOns: addOns,
      );
      emit(OfferBookingFlowQuoteReady(q));
    } catch (e) {
      if (_isConflict(e)) {
        emit(OfferBookingFlowConflict(_normalizeErrorMessage(e)));
        return;
      }
      emit(OfferBookingFlowError(_normalizeErrorMessage(e)));
    }
  }

  Future<void> submitBooking({
    required String offerProductId,
    List<Map<String, dynamic>>? addOns,
    String? contactPhone,
    required bool acceptedTerms,
  }) async {
    emit(OfferBookingFlowLoading());
    try {
      final r = await createUseCase(
        offerProductId: offerProductId,
        addOns: addOns,
        contactPhone: contactPhone,
        acceptedTerms: acceptedTerms,
      );
      emit(OfferBookingFlowCreated(r));
    } catch (e) {
      if (_isConflict(e)) {
        emit(OfferBookingFlowConflict(_normalizeErrorMessage(e)));
        return;
      }
      emit(OfferBookingFlowError(_normalizeErrorMessage(e)));
    }
  }

  bool _isConflict(Object error) {
    if (error is! DioException) return false;
    if (error.response?.statusCode != 409) return false;
    return true;
  }

  String _normalizeErrorMessage(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
