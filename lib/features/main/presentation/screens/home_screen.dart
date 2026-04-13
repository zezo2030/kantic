import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../home/presentation/cubit/home_state.dart';
import '../../../home/presentation/widgets/banner_carousel.dart';
import '../../../home/presentation/widgets/home_shimmer_loading.dart';
import '../../../home/presentation/widgets/home_header_widget.dart';
import '../../../home/presentation/widgets/featured_offers_section.dart';
import '../../../home/presentation/widgets/popular_branches_section.dart';
import '../../../home/presentation/widgets/nearby_branches_section.dart';
import '../cubit/main_navigation_cubit.dart';
import '../../../home/presentation/pages/all_offers_page.dart';
import '../../../branches/presentation/pages/branches_map_page.dart';
import '../../../branches/presentation/cubit/branches_cubit.dart';
import '../../../branches/presentation/cubit/branches_state.dart';
import '../../../branches/data/branches_api.dart';
import '../../../branches/data/branches_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BranchesCubit(repository: BranchesRepositoryImpl(api: BranchesApi()))
            ..loadAll(),
      child: Scaffold(
        floatingActionButton: BlocBuilder<BranchesCubit, BranchesState>(
          builder: (context, branchesState) {
            // إظهار الزر دائماً - تصميم أصغر وشفاف
            return Container(
              margin: const EdgeInsets.only(bottom: 20), // إنزال الزر قليلاً
              child: FloatingActionButton(
                onPressed: branchesState.loading
                    ? null // معطل أثناء التحميل
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BranchesMapPage(
                              branches: branchesState.branches,
                            ),
                          ),
                        );
                      },
                backgroundColor: branchesState.loading
                    ? Theme.of(context).primaryColor.withOpacity(0.6)
                    : Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.85), // شفافية أقل
                elevation: 2,
                mini: true, // زر أصغر
                child: branchesState.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Iconsax.map_1, size: 20),
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeInitial) {
              context.read<HomeCubit>().loadHomeData();
              return const HomeShimmerLoading();
            } else if (state is HomeLoading) {
              return const HomeShimmerLoading();
            } else if (state is HomeLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<HomeCubit>().refreshHomeData(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Home Header
                    SliverToBoxAdapter(child: HomeHeaderWidget()),

                    // Spacing between header and next section
                    const SliverToBoxAdapter(child: SizedBox(height: 50)),

                    // Quick Stats removed per request

                    // Banner Carousel
                    if (state.data.banners.isNotEmpty)
                      SliverToBoxAdapter(
                        child: BannerCarousel(banners: state.data.banners),
                      ),

                    // Spacing before Featured Offers Section
                    if (state.data.offers.isNotEmpty)
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),

                    // Featured Offers Section (Main Focus)
                    if (state.data.offers.isNotEmpty)
                      SliverToBoxAdapter(
                        child: FeaturedOffersSection(
                          offers: state.data.offers,
                          onViewAll: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AllOffersPage(offers: state.data.offers),
                              ),
                            );
                          },
                        ),
                      ),

                    // Popular Branches Section
                    if (state.data.featuredBranches.isNotEmpty)
                      SliverToBoxAdapter(
                        child: PopularBranchesSection(
                          branches: state.data.featuredBranches
                              .take(5)
                              .toList(),
                          onViewAll: () {
                            // الانتقال لتبويب الفروع/التصنيفات
                            context.read<MainNavigationCubit>().changeTab(2);
                          },
                        ),
                      ),

                    // Nearby Branches Section (based on all branches when available)
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
                              // الانتقال لتبويب الفروع/التصنيفات
                              context.read<MainNavigationCubit>().changeTab(2);
                            },
                          );
                        },
                      ),
                    ),

                    // Recommendations Section removed per request

                    // Featured branches section removed per request

                    // Empty state if no data
                    if (state.data.banners.isEmpty &&
                        state.data.offers.isEmpty &&
                        state.data.featuredBranches.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'no_content_available'.tr(),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'check_back_later'.tr(),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Bottom padding
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            } else if (state is HomeError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'error_loading_data'.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.red[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.read<HomeCubit>().loadHomeData(),
                        icon: const Icon(Icons.refresh),
                        label: Text('retry'.tr()),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
