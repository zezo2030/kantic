import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../pages/youtube_player_page.dart';

class HallVideoPlayer extends StatelessWidget {
  final String videoUrl;

  const HallVideoPlayer({super.key, required this.videoUrl});

  String? _extractVideoId(String url) {
    if (url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // Check for watch?v= format
    if (uri.host.contains('youtube.com') && uri.pathSegments.contains('watch')) {
      return uri.queryParameters['v'];
    }

    // Check for youtu.be format
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    // Check for embed format
    if (uri.pathSegments.contains('embed')) {
      final embedIndex = uri.pathSegments.indexOf('embed');
      if (embedIndex < uri.pathSegments.length - 1) {
        return uri.pathSegments[embedIndex + 1];
      }
    }

    // Check for short format
    if (uri.host.contains('youtube.com') && uri.pathSegments.contains('shorts')) {
      final shortsIndex = uri.pathSegments.indexOf('shorts');
      if (shortsIndex < uri.pathSegments.length - 1) {
        return uri.pathSegments[shortsIndex + 1];
      }
    }

    return null;
  }

  String _getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  Future<void> _openVideo(BuildContext context) async {
    try {
      final videoId = _extractVideoId(videoUrl);
      if (videoId != null && videoId.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => YoutubePlayerPage(
              videoId: videoId,
              title: 'video'.tr(),
              fallbackUrl: videoUrl,
            ),
          ),
        );
        return;
      }

      // Ensure the URL has a proper scheme
      String urlToLaunch = videoUrl.trim();
      if (!urlToLaunch.startsWith('http://') && !urlToLaunch.startsWith('https://')) {
        urlToLaunch = 'https://$urlToLaunch';
      }
      
      final uri = Uri.parse(urlToLaunch);
      
      // Check if URL can be launched
      if (!await canLaunchUrl(uri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('cannot_open_video'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Try to launch the URL
      // First try external application (browser or YouTube app)
      try {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        // If external launch fails, try platform default
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (_) {
          // If still failed, try in-app browser
          try {
            await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView,
            );
          } catch (_) {
            // All launch modes failed
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('cannot_open_video'.tr()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('video_load_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _extractVideoId(videoUrl);
    
    if (videoId == null || videoId.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Iconsax.video_slash,
                color: Colors.red[300],
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'invalid_video_url'.tr(),
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final thumbnailUrl = _getThumbnailUrl(videoId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Iconsax.video,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'video'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Thumbnail image
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: Icon(
                      Iconsax.video,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                // Dark overlay
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                // Play button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openVideo(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Iconsax.play,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openVideo(context),
                icon: const Icon(Iconsax.play_circle),
                label: Text('watch_video'.tr()),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
