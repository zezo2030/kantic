import '../../../../core/utils/api_json.dart';
import '../../domain/entities/subscription_usage_log_entity.dart';

class SubscriptionUsageLogModel extends SubscriptionUsageLogEntity {
  const SubscriptionUsageLogModel({
    required super.id,
    super.staffName,
    required super.deductedHours,
    required super.remainingHoursBefore,
    required super.remainingHoursAfter,
    required super.dailyUsedBefore,
    required super.dailyUsedAfter,
    super.notes,
    required super.createdAt,
  });

  factory SubscriptionUsageLogModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionUsageLogModel(
      id: json['id']?.toString() ?? '',
      staffName: json['staffName']?.toString(),
      deductedHours: toDouble(json['deductedHours']) ?? 0,
      remainingHoursBefore: toDouble(json['remainingHoursBefore']) ?? 0,
      remainingHoursAfter: toDouble(json['remainingHoursAfter']) ?? 0,
      dailyUsedBefore: toDouble(json['dailyUsedBefore']) ?? 0,
      dailyUsedAfter: toDouble(json['dailyUsedAfter']) ?? 0,
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }
}
