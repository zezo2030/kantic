import 'package:equatable/equatable.dart';
import '../../../home/domain/entities/branch_entity.dart';

class BranchesState extends Equatable {
  final bool loading;
  final List<BranchEntity> branches;
  final String? error;

  const BranchesState({
    required this.loading,
    required this.branches,
    this.error,
  });

  factory BranchesState.initial() =>
      const BranchesState(loading: false, branches: <BranchEntity>[]);

  BranchesState copyWith({
    bool? loading,
    List<BranchEntity>? branches,
    String? error,
  }) {
    return BranchesState(
      loading: loading ?? this.loading,
      branches: branches ?? this.branches,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, branches, error];
}
