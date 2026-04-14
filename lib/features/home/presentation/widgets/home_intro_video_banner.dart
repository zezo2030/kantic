import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';

/// Inline intro video from CMS (`/home` → `introVideo`), replaces static promo strip.
class HomeIntroVideoBanner extends StatefulWidget {
  final String videoUrl;
  final String? coverUrl;

  const HomeIntroVideoBanner({
    super.key,
    required this.videoUrl,
    this.coverUrl,
  });

  @override
  State<HomeIntroVideoBanner> createState() => _HomeIntroVideoBannerState();
}

class _HomeIntroVideoBannerState extends State<HomeIntroVideoBanner> {
  VideoPlayerController? _video;
  ChewieController? _chewie;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant HomeIntroVideoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposePlayers();
      _init();
    }
  }

  Future<void> _init() async {
    if (widget.videoUrl.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
    );

    try {
      await controller.initialize();
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() {});
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }

    _chewie = ChewieController(
      videoPlayerController: controller,
      autoPlay: false,
      looping: false,
      showControls: true,
      aspectRatio: controller.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primaryRed,
        handleColor: AppColors.primaryRed,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white38,
      ),
      errorBuilder: (_, __) => const Center(
        child: Icon(Icons.error_outline, color: Colors.white54, size: 40),
      ),
    );

    setState(() {
      _video = controller;
    });
  }

  void _disposePlayers() {
    _chewie?.dispose();
    _chewie = null;
    _video = null;
  }

  @override
  void dispose() {
    _disposePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasPlayer =
        _chewie != null && _video != null && _video!.value.isInitialized;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.luxuryShadowMedium,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: hasPlayer ? _video!.value.aspectRatio : 16 / 9,
            child: hasPlayer
                ? ColoredBox(
                    color: Colors.black,
                    child: Chewie(controller: _chewie!),
                  )
                : _coverOrPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _coverOrPlaceholder() {
    final cover = widget.coverUrl;
    if (cover != null && cover.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: cover,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.luxurySurfaceVariant),
            errorWidget: (_, __, ___) =>
                Container(color: AppColors.luxurySurfaceVariant),
          ),
          Container(
            color: Colors.black26,
            child: const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      color: AppColors.luxurySurfaceVariant,
      child: const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryRed,
          ),
        ),
      ),
    );
  }
}
