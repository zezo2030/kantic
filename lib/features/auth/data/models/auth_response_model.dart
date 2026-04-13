import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/auth_response_entity.dart';
import 'user_model.dart';

part 'auth_response_model.g.dart';

@JsonSerializable()
class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final bool? isNewUser;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.isNewUser,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);

  factory AuthResponseModel.fromEntity(AuthResponseEntity entity) {
    return AuthResponseModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      user: UserModel.fromEntity(entity.user),
      isNewUser: entity.isNewUser,
    );
  }

  AuthResponseEntity toEntity() {
    return AuthResponseEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user.toEntity(),
      isNewUser: isNewUser,
    );
  }
}
