import 'package:equatable/equatable.dart';

class SubscriptionUsageLogEntity extends Equatable {
  final String id;
  final String? staffName;
  final double deductedHours;
  final double remainingHoursBefore;
  final double remainingHoursAfter;
  final double dailyUsedBefore;
  final double dailyUsedAfter;
  final String? notes;
  final DateTime createdAt;

  const SubscriptionUsageLogEntity({
    required this.id,
    this.staffName,
    required this.deductedHours,
    required this.remainingHoursBefore,
    required this.remainingHoursAfter,
    required this.dailyUsedBefore,
    required this.dailyUsedAfter,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, createdAt];
}
