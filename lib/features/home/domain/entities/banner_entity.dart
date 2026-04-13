import 'package:equatable/equatable.dart';

class BannerEntity extends Equatable {
  final String id;
  final String? title;
  final String imageUrl;
  final String? link;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BannerEntity({
    required this.id,
    this.title,
    required this.imageUrl,
    this.link,
    this.startsAt,
    this.endsAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    imageUrl,
    link,
    startsAt,
    endsAt,
    isActive,
    createdAt,
    updatedAt,
  ];
}
