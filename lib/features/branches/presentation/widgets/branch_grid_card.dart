import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../home/domain/entities/branch_entity.dart';
import '../../../../core/utils/url_utils.dart';

class BranchGridCard extends StatelessWidget {
  final BranchEntity branch;
  final VoidCallback? onTap;

  const BranchGridCard({super.key, required this.branch, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String? img =
        branch.coverImage ??
        ((branch.images?.isNotEmpty ?? false) ? branch.images!.first : null);

    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar'
        ? branch.nameAr
        : branch.nameEn;

    final String ratingText = (branch.rating ?? 0).toStringAsFixed(1);
    final String location = branch.location;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: img == null || img.isEmpty
                  ? Container(
                      color: Theme.of(context).primaryColor.withOpacity(0.08),
                      child: Icon(
                        Icons.location_on,
                        size: 48,
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: (() {
                        final u = resolveFileUrl(img);
                        // ignore: avoid_print
                        return u;
                      })(),
                      fit: BoxFit.cover,
                      placeholder: (c, u) =>
                          Container(color: Colors.grey.shade300),
                      errorWidget: (c, u, e) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          size: 36,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),

            // gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
            ),

            // content
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        ratingText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
