import 'package:equatable/equatable.dart';

class SubscriptionPurchaseEntity extends Equatable {
  final String id;
  final String userId;
  final String branchId;
  final String subscriptionPlanId;
  final Map<String, dynamic> planSnapshot;
  final double? totalHours;
  final double? remainingHours;
  final double? dailyHoursLimit;
  final DateTime startedAt;
  final DateTime endsAt;
  final String status;
  final String paymentStatus;
  final String? qrData;

  const SubscriptionPurchaseEntity({
    required this.id,
    required this.userId,
    required this.branchId,
    required this.subscriptionPlanId,
    required this.planSnapshot,
    this.totalHours,
    this.remainingHours,
    this.dailyHoursLimit,
    required this.startedAt,
    required this.endsAt,
    required this.status,
    required this.paymentStatus,
    this.qrData,
  });

  String get planTitle =>
      (planSnapshot['title'] ?? planSnapshot['planTitle'] ?? '')
          .toString();

  @override
  List<Object?> get props => [id, status, paymentStatus];
}
