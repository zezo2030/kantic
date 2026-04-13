import 'package:equatable/equatable.dart';

class TripParticipantsUploadEntity extends Equatable {
  final List<int> bytes;
  final String filename;
  final String? contentType;

  const TripParticipantsUploadEntity({
    required this.bytes,
    required this.filename,
    this.contentType,
  });

  @override
  List<Object?> get props => [bytes, filename, contentType];
}

