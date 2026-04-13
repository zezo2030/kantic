import 'package:equatable/equatable.dart';

class OrganizingBranchEntity extends Equatable {
  final String id;
  final String? imageUrl;
  final String? videoUrl;
  final String? videoCoverUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrganizingBranchEntity({
    required this.id,
    this.imageUrl,
    this.videoUrl,
    this.videoCoverUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        imageUrl,
        videoUrl,
        videoCoverUrl,
        isActive,
        createdAt,
        updatedAt,
      ];
}





