import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_branch_details_usecase.dart';
import 'branch_details_state.dart';

class BranchDetailsCubit extends Cubit<BranchDetailsState> {
  final GetBranchDetailsUseCase getBranchDetailsUseCase;

  BranchDetailsCubit({required this.getBranchDetailsUseCase}) : super(BranchDetailsInitial());

  Future<void> loadBranchDetails(String branchId) async {
    emit(BranchDetailsLoading());
    
    final result = await getBranchDetailsUseCase(branchId);
    
    result.fold(
      (failure) => emit(BranchDetailsError(message: failure.message)),
      (branch) => emit(BranchDetailsLoaded(branch: branch)),
    );
  }
}
