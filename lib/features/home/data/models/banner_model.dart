import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/banner_entity.dart';

part 'banner_model.g.dart';

@JsonSerializable()
class BannerModel extends BannerEntity {
  const BannerModel({
    required super.id,
    super.title,
    required super.imageUrl,
    super.link,
    super.startsAt,
    super.endsAt,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      link: json['link']?.toString(),
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'].toString())
          : null,
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'].toString())
          : null,
      isActive: json['isActive'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => _$BannerModelToJson(this);

  factory BannerModel.fromEntity(BannerEntity entity) {
    return BannerModel(
      id: entity.id,
      title: entity.title,
      imageUrl: entity.imageUrl,
      link: entity.link,
      startsAt: entity.startsAt,
      endsAt: entity.endsAt,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  BannerEntity toEntity() {
    return BannerEntity(
      id: id,
      title: title,
      imageUrl: imageUrl,
      link: link,
      startsAt: startsAt,
      endsAt: endsAt,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
