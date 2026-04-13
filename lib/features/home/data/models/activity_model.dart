import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/activity_entity.dart';

part 'activity_model.g.dart';

@JsonSerializable(createFactory: false)
class ActivityModel extends ActivityEntity {
  const ActivityModel({
    required super.id,
    super.imageUrl,
    super.videoUrl,
    super.videoCoverUrl,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      videoCoverUrl: json['videoCoverUrl']?.toString(),
      isActive: json['isActive'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => _$ActivityModelToJson(this);

  factory ActivityModel.fromEntity(ActivityEntity entity) {
    return ActivityModel(
      id: entity.id,
      imageUrl: entity.imageUrl,
      videoUrl: entity.videoUrl,
      videoCoverUrl: entity.videoCoverUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ActivityEntity toEntity() {
    return ActivityEntity(
      id: id,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      videoCoverUrl: videoCoverUrl,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

