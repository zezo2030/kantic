import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/offer_booking_model.dart';
import '../../domain/usecases/get_my_offer_bookings_usecase.dart';

abstract class MyOfferBookingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MyOfferBookingsInitial extends MyOfferBookingsState {}

class MyOfferBookingsLoading extends MyOfferBookingsState {}

class MyOfferBookingsLoaded extends MyOfferBookingsState {
  final List<OfferBookingModel> items;
  final int page;
  final int totalPages;

  MyOfferBookingsLoaded({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [items, page, totalPages];
}

class MyOfferBookingsError extends MyOfferBookingsState {
  final String message;

  MyOfferBookingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class MyOfferBookingsCubit extends Cubit<MyOfferBookingsState> {
  final GetMyOfferBookingsUseCase getMy;

  MyOfferBookingsCubit({required this.getMy}) : super(MyOfferBookingsLoading());

  Future<void> refresh() async {
    await loadPage(1, append: false);
  }

  Future<void> loadPage(int page, {bool append = false}) async {
    try {
      final r = await getMy(page: page, limit: 10);
      if (append && state is MyOfferBookingsLoaded) {
        final prev = (state as MyOfferBookingsLoaded).items;
        emit(
          MyOfferBookingsLoaded(
            items: [...prev, ...r.items],
            page: r.page,
            totalPages: r.totalPages,
          ),
        );
      } else {
        emit(
          MyOfferBookingsLoaded(
            items: r.items,
            page: r.page,
            totalPages: r.totalPages,
          ),
        );
      }
    } catch (e) {
      emit(MyOfferBookingsError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state is! MyOfferBookingsLoaded) return;
    final s = state as MyOfferBookingsLoaded;
    if (s.page >= s.totalPages) return;
    await loadPage(s.page + 1, append: true);
  }
}
