import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../../../../core/utils/url_utils.dart';
import '../pages/youtube_player_page.dart';
import '../pages/video_player_page.dart';
import '../../domain/entities/organizing_branch_entity.dart';

class OrganizingBranchCarousel extends StatefulWidget {
  final List<OrganizingBranchEntity> organizingBranches;

  const OrganizingBranchCarousel({super.key, required this.organizingBranches});

  @override
  State<OrganizingBranchCarousel> createState() => _OrganizingBranchCarouselState();
}

class _OrganizingBranchCarouselState extends State<OrganizingBranchCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  bool _isCloudinaryVideo(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('cloudinary.com') || url.contains('res.cloudinary.com');
  }

  String? _extractYoutubeVideoId(String url) {
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;

    // watch?v=
    if (uri.host.contains('youtube.com') &&
        uri.pathSegments.contains('watch')) {
      return uri.queryParameters['v'];
    }
    // youtu.be/<id>
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
    }
    // /shorts/<id>
    if (uri.host.contains('youtube.com') &&
        uri.pathSegments.contains('shorts')) {
      final shortsIndex = uri.pathSegments.indexOf('shorts');
      if (shortsIndex >= 0 && shortsIndex < uri.pathSegments.length - 1) {
        return uri.pathSegments[shortsIndex + 1];
      }
    }
    // /embed/<id>
    if (uri.pathSegments.contains('embed')) {
      final embedIndex = uri.pathSegments.indexOf('embed');
      if (embedIndex >= 0 && embedIndex < uri.pathSegments.length - 1) {
        return uri.pathSegments[embedIndex + 1];
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchVideo(String videoUrl) async {
    // Check if it's Cloudinary video
    if (_isCloudinaryVideo(videoUrl)) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VideoPlayerPage(videoUrl: videoUrl)),
      );
      return;
    }

    // YouTube video - use existing logic
    final videoId = _extractYoutubeVideoId(videoUrl);
    if (videoId != null && videoId.isNotEmpty) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              YoutubePlayerPage(videoId: videoId, fallbackUrl: videoUrl),
        ),
      );
      return;
    }

    // Fallback: open externally if it's not a valid YouTube URL/id
    final launchUri = Uri.tryParse(videoUrl);
    if (launchUri == null) return;
    if (await launcher.canLaunchUrl(launchUri)) {
      await launcher.launchUrl(
        launchUri,
        mode: launcher.LaunchMode.externalApplication,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text('unable_to_open_video'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.organizingBranches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.organizingBranches.length,
            itemBuilder: (context, index) {
              final organizingBranch = widget.organizingBranches[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16 : 8,
                  right: index == widget.organizingBranches.length - 1 ? 16 : 8,
                ),
                child: _OrganizingBranchItem(
                  organizingBranch: organizingBranch,
                  onVideoTap: organizingBranch.videoUrl != null
                      ? () => _launchVideo(organizingBranch.videoUrl!)
                      : null,
                ),
              );
            },
          ),
        ),
        if (widget.organizingBranches.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.organizingBranches.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Theme.of(context).primaryColor
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OrganizingBranchItem extends StatelessWidget {
  final OrganizingBranchEntity organizingBranch;
  final VoidCallback? onVideoTap;

  const _OrganizingBranchItem({required this.organizingBranch, this.onVideoTap});

  bool _isCloudinaryVideo(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('cloudinary.com') || url.contains('res.cloudinary.com');
  }

  String? _getVideoThumbnail(String videoUrl) {
    // Check if it's Cloudinary video
    if (_isCloudinaryVideo(videoUrl)) {
      try {
        final uri = Uri.parse(videoUrl);
        // Cloudinary provides thumbnail by appending transformation to URL
        // Format: https://res.cloudinary.com/cloud_name/video/upload/v1234567890/folder/video.mp4
        // Thumbnail: replace /upload/ with /upload/w_800,h_450,c_fill,q_auto,f_auto/
        if (uri.pathSegments.contains('upload')) {
          final uploadIndex = uri.pathSegments.indexOf('upload');
          if (uploadIndex >= 0 && uploadIndex < uri.pathSegments.length - 1) {
            // Build thumbnail URL by inserting transformation
            final pathSegments = List<String>.from(uri.pathSegments);
            pathSegments.insert(
              uploadIndex + 1,
              'w_800,h_450,c_fill,q_auto,f_auto',
            );
            final thumbnailPath = pathSegments.join('/');
            return '${uri.scheme}://${uri.host}/$thumbnailPath';
          }
        }
        // Fallback: try to get thumbnail by replacing video extension
        if (videoUrl.contains('.mp4') ||
            videoUrl.contains('.mov') ||
            videoUrl.contains('.webm')) {
          return videoUrl.replaceAll(RegExp(r'\.(mp4|mov|webm)$'), '.jpg');
        }
      } catch (e) {
        // Invalid URL
      }
      return null;
    }

    // YouTube video - use existing logic
    try {
      final uri = Uri.parse(videoUrl);
      String? videoId;

      if (uri.host.contains('youtube.com') &&
          uri.pathSegments.contains('watch')) {
        videoId = uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      }

      if (videoId != null) {
        return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
      }
    } catch (e) {
      // Invalid URL
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = organizingBranch.videoUrl != null;

    // Determine image URL to display
    String? imageUrl;
    if (isVideo) {
      // Priority: videoCoverUrl > dynamic thumbnail

      if (organizingBranch.videoCoverUrl != null &&
          organizingBranch.videoCoverUrl!.isNotEmpty) {
        // Cloudinary URLs are already absolute, no need to resolve
        imageUrl =
            organizingBranch.videoCoverUrl!.startsWith('http://') ||
                organizingBranch.videoCoverUrl!.startsWith('https://')
            ? organizingBranch.videoCoverUrl!
            : resolveFileUrl(organizingBranch.videoCoverUrl!);
      } else {
        imageUrl = _getVideoThumbnail(organizingBranch.videoUrl!);
      }
    } else {
      imageUrl = organizingBranch.imageUrl != null
          ? resolveFileUrl(organizingBranch.imageUrl!)
          : null;
    }

    return GestureDetector(
      onTap: onVideoTap,
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  cacheKey: imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  maxWidthDiskCache: 1000,
                  maxHeightDiskCache: 1000,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 50,
                      ),
                    );
                  },
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 50,
                  ),
                ),
              // Video play button overlay
              if (isVideo)
                Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

