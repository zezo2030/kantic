// Branch Slots Model - Data Layer
import '../../domain/entities/hall_slots_entity.dart';
import 'time_slot_model.dart';

class BranchSlotsModel extends BranchSlotsEntity {
  const BranchSlotsModel({
    required super.slotMinutes,
    required List<TimeSlotModel> super.slots,
  });

  factory BranchSlotsModel.fromJson(Map<String, dynamic> json) {
    final slotsJson = json['slots'] as List<dynamic>? ?? [];
    final slots = slotsJson
        .whereType<Map<String, dynamic>>()
        .map(TimeSlotModel.fromJson)
        .toList();

    final slotMinutes = (json['slotMinutes'] as num?)?.toInt() ?? 60;

    return BranchSlotsModel(slotMinutes: slotMinutes, slots: slots);
  }

  Map<String, dynamic> toJson() {
    return {
      'slotMinutes': slotMinutes,
      'slots': slots.map((slot) => (slot as TimeSlotModel).toJson()).toList(),
    };
  }
}

// Deprecated: Use BranchSlotsModel instead
@Deprecated('Use BranchSlotsModel instead')
typedef HallSlotsModel = BranchSlotsModel;
