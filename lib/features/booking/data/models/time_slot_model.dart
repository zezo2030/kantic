// Time Slot Model - Data Layer
import '../../domain/entities/time_slot_entity.dart';

class TimeSlotModel extends TimeSlotEntity {
  const TimeSlotModel({
    required super.start,
    required super.end,
    required super.available,
    required super.consecutiveSlots,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    final start = json['start'] as String?;
    final end = json['end'] as String?;

    return TimeSlotModel(
      start: start != null ? DateTime.parse(start).toLocal() : DateTime.now(),
      end: end != null ? DateTime.parse(end).toLocal() : DateTime.now(),
      available: json['available'] as bool? ?? false,
      consecutiveSlots: (json['consecutiveSlots'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'available': available,
      'consecutiveSlots': consecutiveSlots,
    };
  }
}
