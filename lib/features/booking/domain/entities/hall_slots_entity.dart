import 'package:equatable/equatable.dart';
import 'time_slot_entity.dart';

class BranchSlotsEntity extends Equatable {
  final int slotMinutes;
  final List<TimeSlotEntity> slots;

  const BranchSlotsEntity({
    required this.slotMinutes,
    required this.slots,
  });

  @override
  List<Object?> get props => [slotMinutes, slots];
}

// Deprecated: Use BranchSlotsEntity instead
@Deprecated('Use BranchSlotsEntity instead')
typedef HallSlotsEntity = BranchSlotsEntity;

