import 'package:equatable/equatable.dart';

class TimeSlotEntity extends Equatable {
  final DateTime start;
  final DateTime end;
  final bool available;
  final int consecutiveSlots;

  const TimeSlotEntity({
    required this.start,
    required this.end,
    required this.available,
    required this.consecutiveSlots,
  });

  @override
  List<Object?> get props => [start, end, available, consecutiveSlots];
}

