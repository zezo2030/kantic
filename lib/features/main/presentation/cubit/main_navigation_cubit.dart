import 'package:flutter_bloc/flutter_bloc.dart';
import 'main_navigation_state.dart';

class MainNavigationCubit extends Cubit<MainNavigationState> {
  MainNavigationCubit() : super(const MainNavigationInitial());

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changeTab(int index) {
    if (index != _currentIndex) {
      _currentIndex = index;
      emit(MainNavigationChanged(currentIndex: _currentIndex));
    }
  }
}
