import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/booking_model.dart';
import '../../../activities/data/bookings_api.dart';

abstract class MyHallTicketsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MyHallTicketsInitial extends MyHallTicketsState {}

class MyHallTicketsLoading extends MyHallTicketsState {}

class MyHallTicketsLoaded extends MyHallTicketsState {
  final List<BookingModel> items;

  MyHallTicketsLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class MyHallTicketsError extends MyHallTicketsState {
  final String message;

  MyHallTicketsError(this.message);

  @override
  List<Object?> get props => [message];
}

class MyHallTicketsCubit extends Cubit<MyHallTicketsState> {
  final BookingsApi _api;

  MyHallTicketsCubit({BookingsApi? api})
      : _api = api ?? BookingsApi(),
        super(MyHallTicketsInitial());

  Future<void> refresh() async {
    emit(MyHallTicketsLoading());
    try {
      final merged = <BookingModel>[];
      var page = 1;
      var hasMore = true;
      const pageSize = 30;
      while (hasMore && page <= 40) {
        final r = await _api.fetch(page: page, pageSize: pageSize);
        merged.addAll(r.items);
        hasMore = r.hasMore;
        page++;
      }
      final seen = <String>{};
      final filtered = <BookingModel>[];
      for (final b in merged) {
        if (!b.showInMyHallTicketsList) continue;
        if (seen.contains(b.id)) continue;
        seen.add(b.id);
        filtered.add(b);
      }
      emit(MyHallTicketsLoaded(filtered));
    } catch (e) {
      emit(MyHallTicketsError(e.toString()));
    }
  }
}
