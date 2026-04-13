// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateProfileDto _$UpdateProfileDtoFromJson(Map<String, dynamic> json) =>
    UpdateProfileDto(
      name: json['name'] as String?,
      email: json['email'] as String?,
      language: json['language'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$UpdateProfileDtoToJson(UpdateProfileDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'language': instance.language,
      'phone': instance.phone,
    };
