import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:easy_localization/easy_localization.dart';
import '../cubit/main_navigation_cubit.dart';
import '../cubit/main_navigation_state.dart';
import '../../../home/presentation/pages/home_tabs_page.dart';
import 'category_screen.dart';
import 'profile_tab_screen.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MainNavigationCubit(),
      child: const MainScreenView(),
    );
  }
}

class MainScreenView extends StatefulWidget {
  const MainScreenView({super.key});

  @override
  State<MainScreenView> createState() => _MainScreenViewState();
}

class _MainScreenViewState extends State<MainScreenView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (authContext, authState) {
        final isGuest = authState is Guest;

        return BlocBuilder<MainNavigationCubit, MainNavigationState>(
          builder: (context, state) {
            final cubit = context.read<MainNavigationCubit>();
            final pages = isGuest
                ? [const HomeTabsPage(), const CategoryScreen()]
                : [
                    const HomeTabsPage(),
                    const CategoryScreen(),
                    const ProfileTabScreen(),
                  ];

            // Keep index valid if available tabs changed after auth state updates.
            final safeIndex = pages.isEmpty
                ? 0
                : cubit.currentIndex.clamp(0, pages.length - 1);

            if (safeIndex != cubit.currentIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  cubit.changeTab(safeIndex);
                }
              });
            }

            // Get current tab title
            String getCurrentTitle() {
              if (isGuest) {
                // For guests, only show home and branches
                switch (safeIndex) {
                  case 0:
                    return 'home'.tr();
                  case 1:
                    return 'branches'.tr();
                  default:
                    return 'home'.tr();
                }
              } else {
                switch (safeIndex) {
                  case 0:
                    return 'home'.tr();
                  case 1:
                    return 'branches'.tr();
                  case 2:
                    return 'profile'.tr();
                  default:
                    return 'home'.tr();
                }
              }
            }

            return PopScope(
              canPop: false, // منع الرجوع للخلف
              child: Scaffold(
                extendBody: true,
                appBar:
                    (isGuest ? safeIndex == 0 : safeIndex == 0)
                    ? null // Home tabs provide their own header
                    : AppBar(
                        title: Text(getCurrentTitle()),
                        centerTitle: true,
                        automaticallyImplyLeading: false,
                      ),
                body: Stack(
                  children: [
                    IndexedStack(
                      index: safeIndex,
                      children: pages,
                    ),
                    Positioned(
                      left: 16.0,
                      right: 16.0,
                      bottom: MediaQuery.of(context).padding.bottom > 0
                          ? MediaQuery.of(context).padding.bottom + 8.0
                          : 24.0,
                      child: _ModernBottomNavBar(
                        cubit: cubit,
                        isGuest: isGuest,
                        selectedIndex: safeIndex,
                        onTap: (index) {
                          if (isGuest) {
                            // For guests, only allow access to home (0) and branches (1)
                            if (index == 0 || index == 1) {
                              cubit.changeTab(index);
                            } else {
                              Navigator.pushNamed(context, '/login');
                            }
                          } else {
                            cubit.changeTab(index);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ModernBottomNavBar extends StatelessWidget {
  final MainNavigationCubit cubit;
  final bool isGuest;
  final int selectedIndex;
  final void Function(int) onTap;

  const _ModernBottomNavBar({
    required this.cubit,
    required this.isGuest,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: isGuest
            ? [
                _NavBarItem(
                  icon: Iconsax.home,
                  activeIcon: Iconsax.home_15,
                  label: 'home'.tr(),
                  isSelected: selectedIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavBarItem(
                  icon: Iconsax.category,
                  activeIcon: Iconsax.category,
                  label: 'branches'.tr(),
                  isSelected: selectedIndex == 1,
                  onTap: () => onTap(1),
                ),
              ]
            : [
                _NavBarItem(
                  icon: Iconsax.home,
                  activeIcon: Iconsax.home_15,
                  label: 'home'.tr(),
                  isSelected: selectedIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavBarItem(
                  icon: Iconsax.category,
                  activeIcon: Iconsax.category,
                  label: 'branches'.tr(),
                  isSelected: selectedIndex == 1,
                  onTap: () => onTap(1),
                ),
                _NavBarItem(
                  icon: Iconsax.profile_circle,
                  activeIcon: Iconsax.profile_circle,
                  label: 'profile'.tr(),
                  isSelected: selectedIndex == 2,
                  onTap: () => onTap(2),
                ),
              ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? primaryColor : Colors.grey.shade400,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              child: isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(width: 0, height: 24),
            ),
          ],
        ),
      ),
    );
  }
}
