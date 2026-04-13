import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';

class YoutubePlayerPage extends StatefulWidget {
  final String videoId;
  final String? title;
  final String? fallbackUrl;

  const YoutubePlayerPage({
    super.key,
    required this.videoId,
    this.title,
    this.fallbackUrl,
  });

  @override
  State<YoutubePlayerPage> createState() => _YoutubePlayerPageState();
}

class _YoutubePlayerPageState extends State<YoutubePlayerPage> {
  late final YoutubePlayerController _controller;
  late final StreamSubscription<YoutubePlayerValue> _sub;
  bool _handledError = false;

  Uri _defaultFallbackUri() {
    final url = widget.fallbackUrl?.trim();
    if (url != null && url.isNotEmpty) {
      final parsed = Uri.tryParse(url);
      if (parsed != null) return parsed;
    }
    return Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}');
  }

  Future<void> _openExternalFallback() async {
    final uri = _defaultFallbackUri();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    )..loadVideoById(videoId: widget.videoId);

    _sub = _controller.stream.listen((value) async {
      if (_handledError) return;
      if (!value.hasError) return;

      _handledError = true;
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('video_unavailable_open_on_youtube'.tr())),
      );

      await _openExternalFallback();
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'video_title'.tr()),
      ),
      body: SafeArea(
        child: YoutubePlayerScaffold(
          controller: _controller,
          builder: (context, player) {
            return Center(child: player);
          },
        ),
      ),
    );
  }
}


