import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import '../../../branches/presentation/cubit/branches_cubit.dart';
import '../../../branches/presentation/cubit/branches_state.dart';
import '../../../branches/data/branches_api.dart';
import '../../../branches/data/branches_repository.dart';
import '../../../branches/presentation/widgets/branch_list_card.dart';
import '../../../branches/presentation/pages/branches_map_page.dart';
import '../../../home/domain/entities/branch_entity.dart';
import '../../../../core/theme/app_colors.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BranchesCubit(repository: BranchesRepositoryImpl(api: BranchesApi()))
            ..loadAll(),
      child: const _CategoryView(),
    );
  }
}

class _CategoryView extends StatefulWidget {
  const _CategoryView();

  @override
  State<_CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<_CategoryView> {
  String _searchQuery = '';
  String _selectedFilter = 'all';

  List<BranchEntity> _filterBranches(List<BranchEntity> branches) {
    var filtered = branches;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((b) {
        return b.nameAr.toLowerCase().contains(query) ||
            b.nameEn.toLowerCase().contains(query) ||
            b.location.toLowerCase().contains(query);
      }).toList();
    }

    switch (_selectedFilter) {
      case 'open':
        filtered = filtered.where((b) => b.status == 'active').toList();
        break;
      case 'capacity':
        filtered = List.from(filtered)
          ..sort((a, b) => b.capacity.compareTo(a.capacity));
        break;
      case 'rating':
        filtered = List.from(filtered)
          ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
    }

    return filtered;
  }

  void _openBranch(BuildContext context, String branchId) {
    Navigator.pushNamed(
      context,
      '/branch-details',
      arguments: {'branchId': branchId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC)),
      child: Column(
        children: [
          // Modern Header with Search and Filters
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'explore'.tr(),
                      style: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    BlocBuilder<BranchesCubit, BranchesState>(
                      builder: (context, state) {
                        return IconButton(
                          onPressed: state.branches.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BranchesMapPage(
                                        branches: state.branches,
                                      ),
                                    ),
                                  );
                                },
                          style: IconButton.styleFrom(
                            backgroundColor: primaryColor.withOpacity(0.1),
                            foregroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Iconsax.map_1),
                          tooltip: 'view_on_map'.tr(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Premium Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(
                      fontFamily: 'MontserratArabic',
                      fontSize: 15,
                      color: Color(0xFF334155),
                    ),
                    decoration: InputDecoration(
                      hintText: 'search_branches'.tr(),
                      hintStyle: const TextStyle(
                        fontFamily: 'MontserratArabic',
                        color: Color(0xFF94A3B8), // slate-400
                        fontSize: 14,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Icon(
                          Iconsax.search_normal_1,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Modern Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'all'.tr(),
                        value: 'all',
                        icon: Iconsax.element_4,
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        label: 'open_now'.tr(),
                        value: 'open',
                        icon: Iconsax.clock,
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        label: 'capacity'.tr(),
                        value: 'capacity',
                        icon: Iconsax.people,
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        label: 'top_rating'.tr(),
                        value: 'rating',
                        icon: Iconsax.star1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Branches List
          Expanded(
            child: BlocBuilder<BranchesCubit, BranchesState>(
              builder: (context, state) {
                if (state.loading && state.branches.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  );
                }

                if (state.error != null && state.branches.isEmpty) {
                  return _buildErrorState(state.error!);
                }

                final filteredBranches = _filterBranches(state.branches);

                if (filteredBranches.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<BranchesCubit>().loadAll(),
                  color: primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredBranches.length,
                    itemBuilder: (context, index) {
                      final b = filteredBranches[index];
                      // Animation placeholder (can be improved with staggered animations)
                      return BranchListCard(
                        branch: b,
                        onTap: () => _openBranch(context, b.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == value;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'MontserratArabic',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.search_favorite,
              size: 64,
              color: Color(0xFFCBD5E1), // slate-300
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'no_branches_found'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
              fontFamily: 'MontserratArabic',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'check_back_later'.tr(),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B), // slate-500
              fontFamily: 'MontserratArabic',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.danger, size: 54, color: Color(0xFFEF4444)),
            const SizedBox(height: 20),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'MontserratArabic',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: () => context.read<BranchesCubit>().loadAll(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('retry'.tr()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
