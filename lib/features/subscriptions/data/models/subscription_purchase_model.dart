import '../../../../core/utils/api_json.dart';
import '../../domain/entities/subscription_purchase_entity.dart';

class SubscriptionPurchaseModel extends SubscriptionPurchaseEntity {
  const SubscriptionPurchaseModel({
    required super.id,
    required super.userId,
    required super.branchId,
    required super.subscriptionPlanId,
    required super.planSnapshot,
    super.totalHours,
    super.remainingHours,
    super.dailyHoursLimit,
    required super.startedAt,
    required super.endsAt,
    required super.status,
    required super.paymentStatus,
    super.qrData,
  });

  factory SubscriptionPurchaseModel.fromJson(Map<String, dynamic> json) {
    final snap = asJsonMap(json['planSnapshot']);
    return SubscriptionPurchaseModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      subscriptionPlanId: json['subscriptionPlanId']?.toString() ?? '',
      planSnapshot: snap.isNotEmpty ? snap : asJsonMap(json['plan']),
      totalHours: toDouble(json['totalHours']),
      remainingHours: toDouble(json['remainingHours']),
      dailyHoursLimit: toDouble(json['dailyHoursLimit']),
      startedAt: parseDate(json['startedAt']) ?? DateTime.now(),
      endsAt: parseDate(json['endsAt']) ?? DateTime.now(),
      status: json['status']?.toString() ?? 'active',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      qrData: json['qrData']?.toString(),
    );
  }
}
