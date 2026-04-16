import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/offer_product_model.dart';
import '../../domain/usecases/get_branch_offer_products_usecase.dart';

abstract class OfferProductsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OfferProductsInitial extends OfferProductsState {}

class OfferProductsLoading extends OfferProductsState {}

class OfferProductsLoaded extends OfferProductsState {
  final List<OfferProductModel> ticketOffers;
  final List<OfferProductModel> hoursOffers;

  OfferProductsLoaded({
    required this.ticketOffers,
    required this.hoursOffers,
  });

  @override
  List<Object?> get props => [ticketOffers, hoursOffers];
}

class OfferProductsError extends OfferProductsState {
  final String message;

  OfferProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

class OfferProductsCubit extends Cubit<OfferProductsState> {
  final GetBranchOfferProductsUseCase getBranch;

  OfferProductsCubit({required this.getBranch}) : super(OfferProductsInitial());

  Future<void> load(String branchId) async {
    emit(OfferProductsLoading());
    try {
      final r = await getBranch(branchId);
      if (isClosed) return;
      emit(
        OfferProductsLoaded(
          ticketOffers: r.ticketOffers,
          hoursOffers: r.hoursOffers,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(OfferProductsError(e.toString()));
    }
  }
}
