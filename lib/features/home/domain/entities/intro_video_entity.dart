import 'package:equatable/equatable.dart';

class IntroVideoEntity extends Equatable {
  final String id;
  final String videoUrl;
  final String? videoCoverUrl;
  final bool isActive;

  const IntroVideoEntity({
    required this.id,
    required this.videoUrl,
    this.videoCoverUrl,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, videoUrl, videoCoverUrl, isActive];
}
