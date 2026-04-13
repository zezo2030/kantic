import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_home_data_usecase.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetHomeDataUseCase getHomeDataUseCase;

  HomeCubit({required this.getHomeDataUseCase}) : super(HomeInitial());

  Future<void> loadHomeData() async {
    if (isClosed) return;
    emit(HomeLoading());
    
    final result = await getHomeDataUseCase();
    
    if (isClosed) return;
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (data) => emit(HomeLoaded(data)),
    );
  }

  Future<void> refreshHomeData() async {
    if (isClosed) return;
    await loadHomeData();
  }
}
