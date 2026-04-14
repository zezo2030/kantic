import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as easy_localization;
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../main/presentation/cubit/main_navigation_cubit.dart';
import '../../../events/presentation/pages/my_event_requests_page.dart';
import '../../../../core/routes/app_route_generator.dart';

/// Professional, highly modernized Home header widget with Glassmorphism
/// and deeply immersive gradients.
class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Header slightly expanded to give a majestic feel
    final headerHeight = screenHeight * 0.28;

    return Container(
      height: headerHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkRed.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Immersive background shapes
          _buildModernShapes(screenWidth, headerHeight),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: headerHeight - MediaQuery.of(context).padding.top,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Top Action Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Right side (Logo)
                            _buildLogoSection(),
                            // Left side (Points & Notif)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildPremiumLoyaltyPoints(),
                                const SizedBox(width: 12),
                                _buildPremiumNotification(context),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          easy_localization.tr('what_would_you_like_to_book_today'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Booking Options Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildBookingOptionsRow(context),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the notification bell button as a glass circle
  Widget _buildPremiumNotification(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationsLoaded) {
          unreadCount = state.unreadCount;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () =>
                          Navigator.pushNamed(context, '/notifications'),
                      child: const Icon(
                        Iconsax.notification,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Premium Badge
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB74D), // Golden badge for contrast
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.deepRed, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Builds the loyalty points widget as a modern glass pill (tappable)
  Widget _buildPremiumLoyaltyPoints() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        int loyaltyPoints = 0;
        if (authState is Authenticated && authState.user.wallet != null) {
          loyaltyPoints = authState.user.wallet!.loyaltyPoints;
        }

        final formattedPoints = _formatPoints(loyaltyPoints);

        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => _navigateToLoyalty(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: [
                      SvgPicture.asset(
                        'assets/imgs/iconloyal.svg',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedPoints,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToLoyalty(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    Navigator.pushNamed(context, AppRoutes.loyalty);
  }

  /// Formats large numbers cleanly
  String _formatPoints(int points) {
    if (points < 1000) {
      return points.toString();
    } else if (points < 1000000) {
      double kValue = points / 1000.0;
      return kValue % 1 == 0
          ? '${kValue.toInt()}K'
          : '${kValue.toStringAsFixed(1)}K';
    } else {
      double mValue = points / 1000000.0;
      return mValue % 1 == 0
          ? '${mValue.toInt()}M'
          : '${mValue.toStringAsFixed(1)}M';
    }
  }

  /// Builds the logo section
  Widget _buildLogoSection() {
    return SizedBox(
      height: 38,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: Image.asset('assets/imgs/logoheader.png', fit: BoxFit.contain),
      ),
    );
  }

  /// Booking options row with enhanced premium drop shadows
  Widget _buildBookingOptionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildBookingButton(
            context,
            imagePath: 'assets/imgs/log1.png',
            onTap: () {
              try {
                context.read<MainNavigationCubit>().changeTab(1);
              } catch (e) {}
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBookingButton(
            context,
            imagePath: 'assets/imgs/log2.png',
            onTap: () => Navigator.pushNamed(context, AppRoutes.schoolTrips),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBookingButton(
            context,
            imagePath: 'assets/imgs/log3.png',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyEventRequestsPage()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingButton(
    BuildContext context, {
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image.asset(imagePath),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds decorative background shapes for depth
  Widget _buildModernShapes(double width, double height) {
    return Stack(
      children: [
        Positioned(
          top: -height * 0.4,
          right: -width * 0.2,
          child: Container(
            width: width * 0.8,
            height: width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white.withOpacity(0.12), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -height * 0.2,
          left: -width * 0.2,
          child: Container(
            width: width * 0.7,
            height: width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white.withOpacity(0.08), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
