import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/home_shimmer_loading.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/featured_offers_section.dart';
import '../widgets/nearby_branches_section.dart';
import '../widgets/activity_carousel.dart';
import '../widgets/organizing_branch_carousel.dart';
import '../../../main/presentation/cubit/main_navigation_cubit.dart';
import 'branches_with_offers_page.dart';
import '../../../branches/presentation/cubit/branches_cubit.dart';
import '../../../branches/presentation/cubit/branches_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../widgets/home_intro_video_banner.dart';

/// Redesigned Home content view without scaffold
/// Integrates seamlessly with the modernized HomeHeaderWidget.
class HomeContentView extends StatelessWidget {
  const HomeContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeInitial) {
          context.read<HomeCubit>().loadHomeData();
          return const HomeShimmerLoading();
        } else if (state is HomeLoading) {
          return const HomeShimmerLoading();
        } else if (state is HomeLoaded) {
          return Container(
            color: AppColors.luxuryBackground, // Subtle light background
            child: RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().refreshHomeData(),
              color: AppColors.primaryRed,
              backgroundColor: Colors.white,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Modernized Home Header
                  const SliverToBoxAdapter(child: HomeHeaderWidget()),

                  // Top spacing after header matching the curve layout
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Intro video from dashboard (replaces static wanasa strip)
                  if (state.data.introVideo != null &&
                      state.data.introVideo!.videoUrl.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Builder(
                        builder: (context) {
                          final intro = state.data.introVideo!;
                          final rawCover = intro.videoCoverUrl;
                          return HomeIntroVideoBanner(
                            videoUrl: resolveFileUrl(intro.videoUrl),
                            coverUrl: rawCover != null && rawCover.isNotEmpty
                                ? resolveFileUrl(rawCover)
                                : null,
                          );
                        },
                      ),
                    ),

                  if (state.data.introVideo != null &&
                      state.data.introVideo!.videoUrl.isNotEmpty)
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Banner Carousel
                  if (state.data.banners.isNotEmpty)
                    SliverToBoxAdapter(
                      child: BannerCarousel(banners: state.data.banners),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Featured Offers Section
                  if (state.data.offers.isNotEmpty)
                    SliverToBoxAdapter(
                      child: FeaturedOffersSection(
                        offers: state.data.offers,
                        featuredBranches: state.data.featuredBranches,
                        onViewAll: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BranchesWithOffersPage(
                                offers: state.data.offers,
                                featuredBranches: state.data.featuredBranches,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Fa3leat Banner - Modernized
                  if (state.data.activities.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.luxuryShadowMedium,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/imgs/fa3leat.png',
                              width: double.infinity,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Activities Section
                  if (state.data.activities.isNotEmpty)
                    SliverToBoxAdapter(
                      child: ActivityCarousel(
                        activities: state.data.activities,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // Nearby Branches Section
                  SliverToBoxAdapter(
                    child: BlocBuilder<BranchesCubit, BranchesState>(
                      builder: (context, branchesState) {
                        final nearbySource = branchesState.branches.isNotEmpty
                            ? branchesState.branches
                            : state.data.featuredBranches;

                        if (nearbySource.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return NearbyBranchesSection(
                          branches: nearbySource,
                          onViewAll: () {
                            try {
                              context.read<MainNavigationCubit>().changeTab(1);
                            } catch (e) {}
                          },
                        );
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Organizing Branches Section
                  if (state.data.organizingBranches.isNotEmpty)
                    SliverToBoxAdapter(
                      child: OrganizingBranchCarousel(
                        organizingBranches: state.data.organizingBranches,
                      ),
                    ),

                  // Empty state if no data
                  if (state.data.banners.isEmpty &&
                      state.data.offers.isEmpty &&
                      state.data.featuredBranches.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.luxurySurfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.home_outlined,
                                  size: 64,
                                  color: AppColors.luxuryTextHint,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'no_content_available'.tr(),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.luxuryTextSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'check_back_later'.tr(),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.luxuryTextHint),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Bottom padding to avoid the bottom navigation bar and floating FAB
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          );
        } else if (state is HomeError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.errorColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'error_loading_data'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.luxuryTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    onPressed: () => context.read<HomeCubit>().loadHomeData(),
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 20,
                    ),
                    text: 'retry',
                    useGradient: true,
                    width: 180,
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
