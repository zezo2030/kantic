import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import '../../../home/domain/entities/branch_entity.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/theme/app_colors.dart';

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
    final isOpen = branch.status == 'active';

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: img == null || img.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryRed.withValues(alpha: 0.12),
                            AppColors.primaryOrange.withValues(alpha: 0.06),
                          ],
                        ),
                      ),
                      child: Icon(
                        Iconsax.gallery,
                        size: 48,
                        color: AppColors.primaryRed.withValues(alpha: 0.25),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: resolveFileUrl(img),
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(
                        color: const Color(0xFFF8FAFC),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryRed.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (c, u, e) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryRed.withValues(alpha: 0.15),
                              AppColors.primaryOrange.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Iconsax.gallery_slash,
                          color: Color(0xFFCBD5E1),
                          size: 36,
                        ),
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
            ),
            if (isOpen)
              Positioned(
                top: 10,
                right: Localizations.localeOf(context).languageCode == 'ar'
                    ? null
                    : 10,
                left: Localizations.localeOf(context).languageCode == 'ar'
                    ? 10
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '●',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (branch.rating != null && branch.rating! > 0)
              Positioned(
                top: 10,
                left: Localizations.localeOf(context).languageCode == 'ar'
                    ? null
                    : 10,
                right: Localizations.localeOf(context).languageCode == 'ar'
                    ? 10
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.luxuryGold.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.star1, size: 11, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        ratingText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Iconsax.location5,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
