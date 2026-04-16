import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../home/domain/entities/branch_entity.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/theme/app_colors.dart';

class BranchListCard extends StatelessWidget {
  final BranchEntity branch;
  final VoidCallback? onTap;

  const BranchListCard({super.key, required this.branch, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String? img =
        branch.coverImage ??
        ((branch.images?.isNotEmpty ?? false) ? branch.images!.first : null);

    final String displayName =
        Localizations.localeOf(context).languageCode == 'ar'
        ? branch.nameAr
        : branch.nameEn;

    final String location = branch.location;
    final isOpen = branch.status == 'active';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'branch_image_${branch.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    child: SizedBox(
                      width: 116,
                      height: 116,
                      child: img == null || img.isEmpty
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primaryRed.withValues(
                                      alpha: 0.15,
                                    ),
                                    AppColors.primaryOrange.withValues(
                                      alpha: 0.08,
                                    ),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Iconsax.gallery,
                                size: 32,
                                color: AppColors.primaryRed.withValues(
                                  alpha: 0.3,
                                ),
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
                                        AppColors.primaryRed.withValues(
                                          alpha: 0.35,
                                        ),
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
                                      AppColors.primaryRed.withValues(
                                        alpha: 0.15,
                                      ),
                                      AppColors.primaryOrange.withValues(
                                        alpha: 0.08,
                                      ),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Iconsax.gallery_slash,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'MontserratArabic',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            if (branch.rating != null && branch.rating! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Iconsax.star1,
                                      size: 12,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      branch.rating!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFD97706),
                                        fontFamily: 'MontserratArabic',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Iconsax.location5,
                              size: 13,
                              color: AppColors.primaryRed.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'MontserratArabic',
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.08)
                                    : const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isOpen
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOpen ? 'open'.tr() : 'closed'.tr(),
                                    style: TextStyle(
                                      color: isOpen
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'MontserratArabic',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (branch.capacity > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Iconsax.people5,
                                      size: 12,
                                      color: Color(0xFF475569),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${branch.capacity} ${'person'.tr()}',
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'MontserratArabic',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (branch.isDecorated == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Iconsax.magicpen5,
                                      size: 12,
                                      color: Color(0xFF8B5CF6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'decorated'.tr(),
                                      style: const TextStyle(
                                        color: Color(0xFF8B5CF6),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'MontserratArabic',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
