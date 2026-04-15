import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import '../../../../core/theme/app_colors.dart';
import '../pages/video_player_page.dart';
import '../pages/youtube_player_page.dart';

/// Intro video from CMS (`/home` → `introVideo`): normal card; tap opens in-app player.
class HomeIntroVideoBanner extends StatelessWidget {
  final String videoUrl;
  final String? coverUrl;

  const HomeIntroVideoBanner({
    super.key,
    required this.videoUrl,
    this.coverUrl,
  });

  static bool _isCloudinaryVideo(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('cloudinary.com') || url.contains('res.cloudinary.com');
  }

  static String? _extractYoutubeVideoId(String url) {
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;

    if (uri.host.contains('youtube.com') &&
        uri.pathSegments.contains('watch')) {
      return uri.queryParameters['v'];
    }
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
    }
    if (uri.host.contains('youtube.com') &&
        uri.pathSegments.contains('shorts')) {
      final shortsIndex = uri.pathSegments.indexOf('shorts');
      if (shortsIndex >= 0 && shortsIndex < uri.pathSegments.length - 1) {
        return uri.pathSegments[shortsIndex + 1];
      }
    }
    if (uri.pathSegments.contains('embed')) {
      final embedIndex = uri.pathSegments.indexOf('embed');
      if (embedIndex >= 0 && embedIndex < uri.pathSegments.length - 1) {
        return uri.pathSegments[embedIndex + 1];
      }
    }
    return null;
  }

  static bool _looksLikeStreamableFile(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.webm') ||
        lower.contains('.m3u8');
  }

  static String? _thumbnailFromVideoUrl(String videoUrl) {
    if (_isCloudinaryVideo(videoUrl)) {
      try {
        final uri = Uri.parse(videoUrl);
        if (uri.pathSegments.contains('upload')) {
          final uploadIndex = uri.pathSegments.indexOf('upload');
          if (uploadIndex >= 0 && uploadIndex < uri.pathSegments.length - 1) {
            final pathSegments = List<String>.from(uri.pathSegments);
            pathSegments.insert(
              uploadIndex + 1,
              'w_800,h_450,c_fill,q_auto,f_auto',
            );
            final thumbnailPath = pathSegments.join('/');
            return '${uri.scheme}://${uri.host}/$thumbnailPath';
          }
        }
        if (videoUrl.contains('.mp4') ||
            videoUrl.contains('.mov') ||
            videoUrl.contains('.webm')) {
          return videoUrl.replaceAll(RegExp(r'\.(mp4|mov|webm)$'), '.jpg');
        }
      } catch (_) {}
      return null;
    }

    final videoId = _extractYoutubeVideoId(videoUrl);
    if (videoId != null && videoId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    }
    return null;
  }

  String? _displayImageUrl() {
    if (coverUrl != null && coverUrl!.isNotEmpty) return coverUrl;
    return _thumbnailFromVideoUrl(videoUrl);
  }

  Future<void> _openPlayer(BuildContext context) async {
    if (videoUrl.isEmpty) return;

    final youtubeId = _extractYoutubeVideoId(videoUrl);
    if (youtubeId != null && youtubeId.isNotEmpty) {
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => YoutubePlayerPage(
            videoId: youtubeId,
            fallbackUrl: videoUrl,
          ),
        ),
      );
      return;
    }

    if (_isCloudinaryVideo(videoUrl) || _looksLikeStreamableFile(videoUrl)) {
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerPage(videoUrl: videoUrl),
        ),
      );
      return;
    }

    final launchUri = Uri.tryParse(videoUrl);
    if (launchUri == null) return;
    if (await launcher.canLaunchUrl(launchUri)) {
      await launcher.launchUrl(
        launchUri,
        mode: launcher.LaunchMode.externalApplication,
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('unable_to_open_video'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (videoUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final imageUrl = _displayImageUrl();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.luxuryTextHint.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openPlayer(context),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ColoredBox(
                      color: AppColors.luxurySurfaceVariant,
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryRed.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: AppColors.luxurySurfaceVariant,
                      child: Icon(
                        Iconsax.video,
                        size: 48,
                        color: AppColors.luxuryTextHint,
                      ),
                    ),
                  )
                else
                  ColoredBox(
                    color: AppColors.luxurySurfaceVariant,
                    child: Icon(
                      Iconsax.video,
                      size: 48,
                      color: AppColors.luxuryTextHint,
                    ),
                  ),
                Container(color: Colors.black26),
                const Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
