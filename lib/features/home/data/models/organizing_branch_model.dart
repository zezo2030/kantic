import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/organizing_branch_entity.dart';

part 'organizing_branch_model.g.dart';

@JsonSerializable(createFactory: false)
class OrganizingBranchModel extends OrganizingBranchEntity {
  const OrganizingBranchModel({
    required super.id,
    super.imageUrl,
    super.videoUrl,
    super.videoCoverUrl,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrganizingBranchModel.fromJson(Map<String, dynamic> json) {
    return OrganizingBranchModel(
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

  Map<String, dynamic> toJson() => _$OrganizingBranchModelToJson(this);

  factory OrganizingBranchModel.fromEntity(OrganizingBranchEntity entity) {
    return OrganizingBranchModel(
      id: entity.id,
      imageUrl: entity.imageUrl,
      videoUrl: entity.videoUrl,
      videoCoverUrl: entity.videoCoverUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  OrganizingBranchEntity toEntity() {
    return OrganizingBranchEntity(
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





