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
      emit(OfferBookingFlowError(e.toString()));
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
      emit(OfferBookingFlowError(e.toString()));
    }
  }
}
