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

class BranchesWithOffersPage extends StatelessWidget {
  final List<OfferEntity> offers;
  final List<BranchEntity>? featuredBranches;

  const BranchesWithOffersPage({
    super.key,
    required this.offers,
    this.featuredBranches,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BranchesCubit(
        repository: BranchesRepositoryImpl(api: BranchesApi()),
      )..loadAll(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('offers'.tr()),
          centerTitle: true,
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

            // تجميع العروض حسب الفرع
            final Map<String, List<OfferEntity>> offersByBranch = {};

            // تجميع العروض حسب اسم الفرع
            for (final offer in offers) {
              if (offer.branchName != null && offer.branchName!.isNotEmpty) {
                // البحث عن الفرع الذي يطابق اسم العرض
                BranchEntity? matchingBranch;
                try {
                  matchingBranch = allBranches.firstWhere(
                    (branch) =>
                        branch.nameAr.toLowerCase().trim() ==
                            offer.branchName!.toLowerCase().trim() ||
                        branch.nameEn.toLowerCase().trim() ==
                            offer.branchName!.toLowerCase().trim(),
                  );
                } catch (e) {
                  // لم يتم العثور على فرع مطابق
                  matchingBranch = null;
                }

                if (matchingBranch != null) {
                  if (!offersByBranch.containsKey(matchingBranch.id)) {
                    offersByBranch[matchingBranch.id] = [];
                  }
                  // تجنب إضافة نفس العرض مرتين
                  if (!offersByBranch[matchingBranch.id]!
                      .any((o) => o.id == offer.id)) {
                    offersByBranch[matchingBranch.id]!.add(offer);
                  }
                }
              }
            }

            // إضافة الفروع التي لديها عروض في بياناتها (حتى لو لم تكن في قائمة العروض)
            for (final branch in allBranches) {
              if (branch.offers != null && branch.offers!.isNotEmpty) {
                if (!offersByBranch.containsKey(branch.id)) {
                  offersByBranch[branch.id] = [];
                }
              }
            }

            // تصفية الفروع التي لديها عروض فقط
            final branchesWithOffers = allBranches
                .where((branch) => offersByBranch.containsKey(branch.id) &&
                    offersByBranch[branch.id]!.isNotEmpty)
                .toList();

            if (branchesState.loading && branchesWithOffers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (branchesWithOffers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.discount_shape,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_content_available'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: branchesWithOffers.length,
              itemBuilder: (context, index) {
                final branch = branchesWithOffers[index];
                final branchOffers = offersByBranch[branch.id] ?? [];

                return _BranchOffersCard(
                  branch: branch,
                  offers: branchOffers,
                  onBranchTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BranchDetailsPage(branchId: branch.id),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BranchOffersCard extends StatelessWidget {
  final BranchEntity branch;
  final List<OfferEntity> offers;
  final VoidCallback onBranchTap;

  const _BranchOffersCard({
    required this.branch,
    required this.offers,
    required this.onBranchTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final branchName = isArabic ? branch.nameAr : branch.nameEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch Header
          GestureDetector(
            onTap: onBranchTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Branch Image
                  if (branch.coverImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: resolveFileUrl(branch.coverImage!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.white.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.white.withOpacity(0.3),
                          child: const Icon(
                            Iconsax.building,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.building,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  const SizedBox(width: 12),
                  // Branch Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branchName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (branch.location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Iconsax.location,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  branch.location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Iconsax.arrow_left_2,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Offers List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'offers'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...offers.map((offer) => _OfferItem(offer: offer)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferItem extends StatelessWidget {
  final OfferEntity offer;

  const _OfferItem({required this.offer});

  @override
  Widget build(BuildContext context) {
    final discountText = offer.discountType == 'percentage'
        ? '${offer.discountValue.toStringAsFixed(0)}%'
        : '${offer.discountValue.toStringAsFixed(0)} ${'riyal'.tr()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Offer Image
          if (offer.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: resolveFileUrl(offer.imageUrl!),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(
                    Iconsax.discount_shape,
                    color: AppColors.primaryRed,
                    size: 30,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.discount_shape,
                color: AppColors.primaryRed,
                size: 30,
              ),
            ),
          const SizedBox(width: 12),
          // Offer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (offer.description != null && offer.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    offer.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Discount Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              discountText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

