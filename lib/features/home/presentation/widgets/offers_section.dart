import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/url_utils.dart';

class OffersSection extends StatelessWidget {
  final List<dynamic>? offers;

  const OffersSection({super.key, this.offers});

  @override
  Widget build(BuildContext context) {
    final list = offers ?? const [];
    if (list.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final offer = list[i];
          final title = (offer is Map && offer['title'] != null)
              ? offer['title'].toString()
              : 'Offer';
          final discount = (offer is Map && offer['discount'] != null)
              ? offer['discount'].toString()
              : null;
          // Derive percentage/fixed discount display if not provided
          String? discountBadge;
          if (offer is Map) {
            final dv = offer['discountValue'];
            final dt = offer['discountType'];
            if (discount != null && discount.trim().isNotEmpty) {
              discountBadge = discount;
            } else if (dv != null && dt != null) {
              final num? Val = dv is num
                  ? dv
                  : (dv is String ? num.tryParse(dv) : null);
              final String type = dt.toString();
              if (Val != null) {
                if (type == 'percentage') {
                  discountBadge = '${Val.toString()}%';
                } else {
                  // fixed amount e.g. SAR 50 off -> keep as numeric here
                  discountBadge = Val.toString();
                }
              }
            }
          }
          final imageUrl = (offer is Map && offer['imageUrl'] != null)
              ? offer['imageUrl'].toString()
              : null;
          return Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Background Image
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: resolveFileUrl(imageUrl),
                        cacheKey: resolveFileUrl(imageUrl),
                        fit: BoxFit.cover,
                        maxWidthDiskCache: 1000,
                        maxHeightDiskCache: 1000,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFFFEDEA),
                          child: const Center(
                            child: Icon(
                              Iconsax.discount_shape,
                              color: Color(0xFFEF4444),
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFFFFEDEA),
                      child: const Center(
                        child: Icon(
                          Iconsax.discount_shape,
                          color: Color(0xFFEF4444),
                          size: 40,
                        ),
                      ),
                    ),

                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Discount badge (top-left)
                  if (discountBadge != null && discountBadge.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.discount_shape,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              discountBadge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (discount != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            discount,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemCount: list.length,
      ),
    );
  }
}
