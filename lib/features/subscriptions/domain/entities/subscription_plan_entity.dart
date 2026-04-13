import 'package:equatable/equatable.dart';

class SubscriptionPlanEntity extends Equatable {
  final String id;
  final String branchId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? termsAndConditions;
  final double price;
  final String currency;
  final String usageMode;
  final double? totalHours;
  final double? dailyHoursLimit;
  final List<String> mealItems;
  final String durationType;
  final int durationMonths;
  final bool isGiftable;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;

  const SubscriptionPlanEntity({
    required this.id,
    required this.branchId,
    required this.title,
    this.description,
    this.imageUrl,
    this.termsAndConditions,
    required this.price,
    required this.currency,
    required this.usageMode,
    this.totalHours,
    this.dailyHoursLimit,
    this.mealItems = const [],
    required this.durationType,
    required this.durationMonths,
    required this.isGiftable,
    required this.isActive,
    this.startsAt,
    this.endsAt,
  });

  @override
  List<Object?> get props => [id, branchId, title, price, usageMode];
}
