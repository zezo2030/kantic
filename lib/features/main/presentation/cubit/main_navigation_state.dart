import 'package:equatable/equatable.dart';

abstract class MainNavigationState extends Equatable {
  const MainNavigationState();

  @override
  List<Object> get props => [];
}

class MainNavigationInitial extends MainNavigationState {
  const MainNavigationInitial();
}

class MainNavigationChanged extends MainNavigationState {
  final int currentIndex;

  const MainNavigationChanged({required this.currentIndex});

  @override
  List<Object> get props => [currentIndex];
}
