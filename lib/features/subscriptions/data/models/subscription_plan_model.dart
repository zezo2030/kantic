import '../../../../core/utils/api_json.dart';
import '../../domain/entities/subscription_plan_entity.dart';

class SubscriptionPlanModel extends SubscriptionPlanEntity {
  const SubscriptionPlanModel({
    required super.id,
    required super.branchId,
    required super.title,
    super.description,
    super.imageUrl,
    super.termsAndConditions,
    required super.price,
    required super.currency,
    required super.usageMode,
    super.totalHours,
    super.dailyHoursLimit,
    super.mealItems = const [],
    required super.durationType,
    required super.durationMonths,
    required super.isGiftable,
    required super.isActive,
    super.startsAt,
    super.endsAt,
  });

  static List<String> _mealItems(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      termsAndConditions: json['termsAndConditions']?.toString(),
      price: toDouble(json['price']) ?? 0,
      currency: json['currency']?.toString() ?? 'SAR',
      usageMode: json['usageMode']?.toString() ?? 'daily_limited',
      totalHours: toDouble(json['totalHours']),
      dailyHoursLimit: toDouble(json['dailyHoursLimit']),
      mealItems: _mealItems(json['mealItems']),
      durationType: json['durationType']?.toString() ?? 'monthly',
      durationMonths: toInt(json['durationMonths']) ?? 1,
      isGiftable: json['isGiftable'] == true,
      isActive: json['isActive'] != false,
      startsAt: parseDate(json['startsAt']),
      endsAt: parseDate(json['endsAt']),
    );
  }
}
