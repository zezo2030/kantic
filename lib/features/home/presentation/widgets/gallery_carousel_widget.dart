import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/url_utils.dart';

class GalleryCarouselWidget extends StatefulWidget {
  final List<String>? images;

  const GalleryCarouselWidget({super.key, required this.images});

  @override
  State<GalleryCarouselWidget> createState() => _GalleryCarouselWidgetState();
}

class _GalleryCarouselWidgetState extends State<GalleryCarouselWidget> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final list = (widget.images ?? [])
        .where((e) => (e).toString().trim().isNotEmpty)
        .toList();
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: list.length,
            onPageChanged: (i) => setState(() => _current = i),
            controller: PageController(viewportFraction: 0.92),
            itemBuilder: (_, i) {
              final url = resolveFileUrl(list[i]);
              return Padding(
                padding: EdgeInsets.only(right: i < list.length - 1 ? 16 : 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    cacheKey: url,
                    fit: BoxFit.cover,
                    maxWidthDiskCache: 1000,
                    maxHeightDiskCache: 1000,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade300),
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.grey.shade300),
                    fadeInDuration: const Duration(milliseconds: 200),
                    fadeOutDuration: const Duration(milliseconds: 200),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(list.length, (i) => i)
              .map(
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _current ? Colors.black87 : Colors.black26,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
