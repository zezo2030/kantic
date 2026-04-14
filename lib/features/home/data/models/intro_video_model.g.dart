// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intro_video_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntroVideoModel _$IntroVideoModelFromJson(Map<String, dynamic> json) =>
    IntroVideoModel(
      id: json['id'] as String,
      videoUrl: json['videoUrl'] as String,
      videoCoverUrl: json['videoCoverUrl'] as String?,
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$IntroVideoModelToJson(IntroVideoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'videoUrl': instance.videoUrl,
      'videoCoverUrl': instance.videoCoverUrl,
      'isActive': instance.isActive,
    };
