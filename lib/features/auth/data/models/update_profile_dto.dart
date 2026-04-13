import 'package:json_annotation/json_annotation.dart';

part 'update_profile_dto.g.dart';

@JsonSerializable()
class UpdateProfileDto {
  final String? name;
  final String? email;
  final String? language;
  final String? phone;

  const UpdateProfileDto({this.name, this.email, this.language, this.phone});

  factory UpdateProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateProfileDtoToJson(this);

  UpdateProfileDto copyWith({
    String? name,
    String? email,
    String? language,
    String? phone,
  }) {
    return UpdateProfileDto(
      name: name ?? this.name,
      email: email ?? this.email,
      language: language ?? this.language,
      phone: phone ?? this.phone,
    );
  }
}
