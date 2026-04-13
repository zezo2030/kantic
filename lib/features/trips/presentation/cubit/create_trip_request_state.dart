import 'package:equatable/equatable.dart';

class CreateTripRequestState extends Equatable {
  final bool isSubmitting;
  final String? requestId;
  final String? errorMessage;

  const CreateTripRequestState({
    required this.isSubmitting,
    this.requestId,
    this.errorMessage,
  });

  factory CreateTripRequestState.initial() {
    return const CreateTripRequestState(
      isSubmitting: false,
      requestId: null,
      errorMessage: null,
    );
  }

  CreateTripRequestState copyWith({
    bool? isSubmitting,
    String? requestId,
    String? errorMessage,
  }) {
    return CreateTripRequestState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      requestId: requestId ?? this.requestId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isSubmitting, requestId, errorMessage];
}

