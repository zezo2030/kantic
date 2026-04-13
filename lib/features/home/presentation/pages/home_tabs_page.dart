import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'home_content_view.dart';
import '../../../branches/presentation/pages/branches_map_content.dart';
import '../../../branches/presentation/cubit/branches_cubit.dart';
import '../../../branches/presentation/cubit/branches_state.dart';
import '../../../branches/data/branches_api.dart';
import '../../../branches/data/branches_repository.dart';
import '../../../../core/widgets/gradient_segmented_toggle.dart';
import '../../../../core/services/location_service_prompt.dart';
import '../cubit/home_cubit.dart';
import '../../di/home_injection.dart';

/// Main home page with tabs for Branches (home) and Map views
/// Features a gradient segmented toggle that persists across both views
class HomeTabsPage extends StatefulWidget {
  const HomeTabsPage({super.key});

  @override
  State<HomeTabsPage> createState() => _HomeTabsPageState();
}

class _HomeTabsPageState extends State<HomeTabsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _homeCubit = sl<HomeCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        promptEnableLocationServiceIfDisabled(context);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _homeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeCubit),
        BlocProvider(
          create: (_) => BranchesCubit(
            repository: BranchesRepositoryImpl(api: BranchesApi()),
          )..loadAll(),
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<BranchesCubit, BranchesState>(
            builder: (context, branchesState) {
              return Stack(
                children: [
                  // Content behind the floating toggle
                  Positioned.fill(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Branches Tab (Home Screen content)
                        const HomeContentView(),

                        // Map Tab
                        branchesState.loading
                            ? const Center(child: CircularProgressIndicator())
                            : branchesState.branches.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.map_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'no_branches_available'.tr(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : BranchesMapContent(
                                branches: branchesState.branches,
                              ),
                      ],
                    ),
                  ),

                  // Floating bottom-center gradient toggle
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom:
                        90, // Positioned above the floating bottom navigation bar
                    child: SafeArea(
                      minimum: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Center(
                          child: FractionallySizedBox(
                            widthFactor:
                                0.50, // further reduce width to match reference pill
                            child: GradientSegmentedToggle(
                              labels: ['branches'.tr(), 'map'.tr()],
                              controller: _tabController,
                              height: 56,
                              borderRadius: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
