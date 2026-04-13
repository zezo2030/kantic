import 'package:equatable/equatable.dart';
import '../../domain/entities/branch_entity.dart';

abstract class BranchDetailsState extends Equatable {
  const BranchDetailsState();

  @override
  List<Object?> get props => [];
}

class BranchDetailsInitial extends BranchDetailsState {}

class BranchDetailsLoading extends BranchDetailsState {}

class BranchDetailsLoaded extends BranchDetailsState {
  final BranchEntity branch;

  const BranchDetailsLoaded({required this.branch});

  @override
  List<Object?> get props => [branch];
}

class BranchDetailsError extends BranchDetailsState {
  final String message;

  const BranchDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}
