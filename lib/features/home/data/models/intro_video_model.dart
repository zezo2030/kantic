import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/intro_video_entity.dart';

part 'intro_video_model.g.dart';

@JsonSerializable()
class IntroVideoModel {
  final String id;
  final String videoUrl;
  final String? videoCoverUrl;
  final bool isActive;

  const IntroVideoModel({
    required this.id,
    required this.videoUrl,
    this.videoCoverUrl,
    required this.isActive,
  });

  factory IntroVideoModel.fromJson(Map<String, dynamic> json) =>
      _$IntroVideoModelFromJson(json);

  Map<String, dynamic> toJson() => _$IntroVideoModelToJson(this);

  factory IntroVideoModel.fromEntity(IntroVideoEntity entity) {
    return IntroVideoModel(
      id: entity.id,
      videoUrl: entity.videoUrl,
      videoCoverUrl: entity.videoCoverUrl,
      isActive: entity.isActive,
    );
  }

  IntroVideoEntity toEntity() {
    return IntroVideoEntity(
      id: id,
      videoUrl: videoUrl,
      videoCoverUrl: videoCoverUrl,
      isActive: isActive,
    );
  }
}
