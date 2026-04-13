import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../../branches/presentation/cubit/branches_cubit.dart';
import '../../../branches/presentation/cubit/branches_state.dart';
import '../../../branches/data/branches_api.dart';
import '../../../branches/data/branches_repository.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/offer_entity.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'branch_details_page.dart';

class OfferBranchesPage extends StatelessWidget {
  final OfferEntity offer;
  final List<BranchEntity>? featuredBranches;

  const OfferBranchesPage({
    super.key,
    required this.offer,
    this.featuredBranches,
  });

  @override
  Widget build(BuildContext context) {
    final offerTitle = offer.title;

    return BlocProvider(
      create: (_) => BranchesCubit(
        repository: BranchesRepositoryImpl(api: BranchesApi()),
      )..loadAll(),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offerTitle,
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'branches'.tr(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: BlocBuilder<BranchesCubit, BranchesState>(
          builder: (context, branchesState) {
            // دمج الفروع المميزة مع جميع الفروع
            final allBranches = <BranchEntity>[];
            if (featuredBranches != null) {
              allBranches.addAll(featuredBranches!);
            }
            if (branchesState.branches.isNotEmpty) {
              // إضافة الفروع التي ليست في القائمة المميزة
              for (final branch in branchesState.branches) {
                if (!allBranches.any((b) => b.id == branch.id)) {
                  allBranches.add(branch);
                }
              }
            }

            // البحث عن الفروع التي تحتوي على هذا العرض
            final matchingBranches = <BranchEntity>[];

            // أولاً: البحث مباشرة من خلال branchId (الطريقة الأفضل والأدق)
            if (offer.branchId != null && offer.branchId!.isNotEmpty) {
              for (final branch in allBranches) {
                if (branch.id == offer.branchId) {
                  if (!matchingBranches.any((b) => b.id == branch.id)) {
                    matchingBranches.add(branch);
                  }
                  break; // وجدنا الفرع، لا حاجة للبحث أكثر
                }
              }
            }

            // ثانياً: البحث من خلال branchName في العرض (fallback)
            if (matchingBranches.isEmpty && 
                offer.branchName != null && offer.branchName!.isNotEmpty) {
              for (final branch in allBranches) {
                if (branch.nameAr.toLowerCase().trim() ==
                        offer.branchName!.toLowerCase().trim() ||
                    branch.nameEn.toLowerCase().trim() ==
                        offer.branchName!.toLowerCase().trim()) {
                  if (!matchingBranches.any((b) => b.id == branch.id)) {
                    matchingBranches.add(branch);
                  }
                }
              }
            }

            // ثالثاً: البحث من خلال offers في بيانات الفرع (fallback)
            if (matchingBranches.isEmpty) {
              for (final branch in allBranches) {
                if (branch.offers != null && branch.offers!.isNotEmpty) {
                  bool hasOffer = false;
                  for (final offerData in branch.offers!) {
                    if (offerData is Map) {
                      // التحقق من تطابق العنوان أو المعرف
                      final offerTitle = offerData['title']?.toString();
                      final offerId = offerData['id']?.toString();
                      if ((offerTitle != null &&
                              offerTitle.toLowerCase().trim() ==
                                  offer.title.toLowerCase().trim()) ||
                          (offerId != null && offerId == offer.id)) {
                        hasOffer = true;
                        break;
                      }
                    }
                  }
                  if (hasOffer &&
                      !matchingBranches.any((b) => b.id == branch.id)) {
                    matchingBranches.add(branch);
                  }
                }
              }
            }

            if (branchesState.loading && matchingBranches.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (matchingBranches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.building,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_branches_with_location'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'no_content_available'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Offer Info Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Offer Image
                      if (offer.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: resolveFileUrl(offer.imageUrl!),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.white.withOpacity(0.3),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.white.withOpacity(0.3),
                              child: const Icon(
                                Iconsax.discount_shape,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Iconsax.discount_shape,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      const SizedBox(width: 16),
                      // Offer Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (offer.description != null &&
                                offer.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                offer.description!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                offer.discountType == 'percentage'
                                    ? '${offer.discountValue.toStringAsFixed(0)}% ${'off'.tr()}'
                                    : '${offer.discountValue.toStringAsFixed(0)} ${'riyal'.tr()} ${'off'.tr()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Branches List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: matchingBranches.length,
                    itemBuilder: (context, index) {
                      final branch = matchingBranches[index];
                      return _BranchCard(
                        branch: branch,
                        offer: offer,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BranchDetailsPage(branchId: branch.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final BranchEntity branch;
  final OfferEntity offer;
  final VoidCallback onTap;

  const _BranchCard({
    required this.branch,
    required this.offer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final branchName = isArabic ? branch.nameAr : branch.nameEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Branch Image
                if (branch.coverImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: resolveFileUrl(branch.coverImage!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(
                          Iconsax.building,
                          color: AppColors.primaryRed,
                          size: 40,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.building,
                      color: AppColors.primaryRed,
                      size: 40,
                    ),
                  ),
                const SizedBox(width: 16),
                // Branch Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branchName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (branch.location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Iconsax.location,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                branch.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (branch.rating != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Iconsax.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              branch.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (branch.reviewsCount != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${branch.reviewsCount})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Iconsax.arrow_left_2,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

