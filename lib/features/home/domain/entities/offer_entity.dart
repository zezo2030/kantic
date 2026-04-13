import 'package:equatable/equatable.dart';

class OfferEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final String? hallName;
  final String? branchName;
  final String? branchId;

  const OfferEntity({
    required this.id,
    required this.title,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.startsAt,
    this.endsAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.hallName,
    this.branchName,
    this.branchId,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    discountType,
    discountValue,
    startsAt,
    endsAt,
    isActive,
    createdAt,
    updatedAt,
    imageUrl,
    hallName,
    branchName,
    branchId,
  ];
}
