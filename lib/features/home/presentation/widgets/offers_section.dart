import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';

class OffersSection extends StatelessWidget {
  final List<dynamic>? offers;

  const OffersSection({super.key, this.offers});

  @override
  Widget build(BuildContext context) {
    final list = offers ?? const [];
    if (list.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _OfferCard(offer: list[i]),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final dynamic offer;

  const _OfferCard({required this.offer});

  String get _title =>
      (offer is Map && offer['title'] != null) ? offer['title'].toString() : 'Offer';

  String? get _discount =>
      (offer is Map && offer['discount'] != null) ? offer['discount'].toString() : null;

  String? get _discountBadge {
    if (offer is! Map) return null;
    final dv = offer['discountValue'];
    final dt = offer['discountType'];
    if (_discount != null && _discount!.trim().isNotEmpty) return _discount;
    if (dv != null && dt != null) {
      final num? val = dv is num ? dv : (dv is String ? num.tryParse(dv) : null);
      if (val != null) {
        return dt.toString() == 'percentage' ? '${val.toString()}%' : val.toString();
      }
    }
    return null;
  }

  String? get _imageUrl {
    if (offer is! Map || offer['imageUrl'] == null) return null;
    return offer['imageUrl'].toString();
  }

  String? get _description =>
      (offer is Map && offer['description'] != null) ? offer['description'].toString() : null;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;
    final resolvedUrl = imageUrl != null && imageUrl.isNotEmpty ? resolveFileUrl(imageUrl) : null;

    return Container(
      width: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ─── Background Image or Gradient ───
            if (resolvedUrl != null)
              CachedNetworkImage(
                imageUrl: resolvedUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _PlaceholderGradient(),
                errorWidget: (_, __, ___) => _PlaceholderGradient(),
              )
            else
              _PlaceholderGradient(),

            // ─── Dark scrim from bottom ───
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                  stops: [0.35, 1.0],
                ),
              ),
            ),

            // ─── Discount badge ───
            if (_discountBadge != null && _discountBadge!.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: _DiscountBadge(text: _discountBadge!),
              ),

            // ─── Content ───
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  if (_description != null && _description!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      _description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (_discount != null && _description == null) ...[
                    const SizedBox(height: 5),
                    Text(
                      _discount!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
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
  }
}

class _PlaceholderGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8A00), Color(0xFFFF5E00), Color(0xFFB30000)],
        ),
      ),
      child: const Center(
        child: Icon(Iconsax.discount_shape, color: Colors.white54, size: 44),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final String text;
  const _DiscountBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.discount_shape, size: 13, color: AppColors.primaryRed),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
