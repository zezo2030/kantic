import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax/iconsax.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/screens/edit_profile_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../loyalty/presentation/screens/loyalty_screen.dart';
import '../../../events/presentation/pages/my_event_requests_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_route_generator.dart';
import 'package:get_it/get_it.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/welcome',
            (route) => false,
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state is ProfileUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('profile_updated_successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ProfileUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state is LanguageUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('language_updated_successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is LanguageUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state is AccountDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('account_deleted'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AccountDeleteError) {
          // Show error dialog for better visibility
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showDeleteAccountErrorDialog(context, state.message);
          });
        }
      },
      builder: (context, state) {
        // Check if user is guest
        if (state is Guest) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamed(context, '/login');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('login_required'.tr()),
                backgroundColor: Colors.orange,
              ),
            );
          });
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AuthLoading ||
            state is ProfileUpdating ||
            state is AccountDeleting) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is Authenticated) {
          return _buildProfileContent(context, state.user);
        } else {
          return _buildErrorContent(context);
        }
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, user) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    // Matches `MainScreen` floating bottom nav `Positioned.bottom`.
    final floatingNavBottomOffset = mediaQuery.padding.bottom > 0
        ? mediaQuery.padding.bottom + 8.0
        : 24.0;
    // `_ModernBottomNavBar` pill height (padding + row + labels) + small gap.
    const floatingNavBarHeight = 96.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + floatingNavBottomOffset + floatingNavBarHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header - Enhanced Design Without Photo
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkRed.withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Avatar with gradient background
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 38,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Name
                            Text(
                              user.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Loyalty Points (tappable)
                            if (user.wallet != null) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _openLoyaltyScreen(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.star1,
                                        color: Colors.amber.shade300,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${user.wallet!.loyaltyPoints} ${'points'.tr()}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Iconsax.arrow_right_1,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            // Phone
                            if (user.phone != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.call,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    user.phone!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Edit Profile Button Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.luxuryBorderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSettingTile(
              context,
              icon: Iconsax.edit,
              title: 'edit_profile'.tr(),
              subtitle: 'edit_profile_subtitle'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle(context, 'subscriptions_and_offers_profile'.tr()),
          const SizedBox(height: 12),
          _buildCommerceShortcutsCard(context),

          const SizedBox(height: 24),

          // Booking Options Section
          _buildSectionTitle(context, 'booking_options'.tr()),
          const SizedBox(height: 12),
          _buildBookingOptionsCard(context),

          const SizedBox(height: 24),

          _buildSectionTitle(context, 'settings'.tr()),
          const SizedBox(height: 12),
          _buildLanguagePreferencesCard(context),

          const SizedBox(height: 24),

          _buildSectionTitle(context, 'menu'.tr()),
          const SizedBox(height: 12),
          _buildFeaturesListCard(context),

          const SizedBox(height: 32),

          // Logout Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Iconsax.logout, size: 20),
              label: Text('logout'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommerceShortcutsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.luxuryBorderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            context,
            icon: Iconsax.card,
            title: 'my_subscriptions'.tr(),
            subtitle: 'my_subscriptions_subtitle'.tr(),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.mySubscriptions),
          ),
          const Divider(height: 24),
          _buildSettingTile(
            context,
            icon: Iconsax.ticket,
            title: 'my_hall_tickets'.tr(),
            subtitle: 'my_hall_tickets_subtitle'.tr(),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.myHallTickets),
          ),
          const Divider(height: 24),
          _buildSettingTile(
            context,
            icon: Iconsax.gift,
            title: 'my_offer_bookings'.tr(),
            subtitle: 'my_offer_bookings_subtitle'.tr(),
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.myOfferBookings),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.luxuryTextPrimary,
      ),
    );
  }

  Widget _buildLanguagePreferencesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.luxuryBorderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildSettingTile(
        context,
        icon: Iconsax.language_square,
        title: 'change_language'.tr(),
        subtitle: context.locale.languageCode == 'ar'
            ? 'language_arabic'.tr()
            : 'language_english'.tr(),
        onTap: () => _showLanguageDialog(context),
      ),
    );
  }

  Widget _buildBookingOptionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.luxuryBorderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // // School Booking
          // _buildSettingTile(
          //   context,
          //   icon: Icons.event_available_outlined,
          //   title: 'school_booking'.tr(),
          //   subtitle: 'school_booking_subtitle'.tr(),
          //   onTap: () {
          //     Navigator.pushNamed(context, '/main');
          //   },
          // ),
          // const Divider(height: 24),
          // School Trips
          _buildSettingTile(
            context,
            icon: Icons.school_outlined,
            title: 'school_trips_title'.tr(),
            subtitle: 'school_trips_subtitle'.tr(),
            onTap: () {
              Navigator.pushNamed(context, '/school-trips');
            },
          ),
          const Divider(height: 24),
          _buildSettingTile(
            context,
            icon: Iconsax.calendar_edit,
            title: 'special_bookings'.tr(),
            subtitle: 'special_bookings'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyEventRequestsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesListCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.luxuryBorderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            context,
            icon: Iconsax.star1,
            title: 'loyalty_program'.tr(),
            subtitle: 'loyalty_program_subtitle'.tr(),
            onTap: () => _openLoyaltyScreen(context),
          ),

          const Divider(height: 24),

          _buildSettingTile(
            context,
            icon: Iconsax.wallet_3,
            title: 'my_wallet'.tr(),
            subtitle: 'view_wallet_balance'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => GetIt.instance<WalletCubit>(),
                    child: const WalletScreen(),
                  ),
                ),
              );
            },
          ),

          const Divider(height: 24),
          _buildSettingTile(
            context,
            icon: Iconsax.document_text_1,
            title: 'privacy_policy'.tr(),
            subtitle: 'privacy_policy_subtitle'.tr(),
            onTap: () => _openPrivacyPolicy(context),
          ),
          const Divider(height: 24),
          _buildSettingTile(
            context,
            icon: Iconsax.user_add,
            title: 'invite_friends'.tr(),
            subtitle: 'invite_friends_subtitle'.tr(),
            onTap: () => _showInviteFriendsDialog(context),
          ),
          const Divider(height: 24),
          _buildSettingTile(
            context,
            icon: Iconsax.trash,
            title: 'delete_account'.tr(),
            subtitle: 'delete_account_confirmation'.tr(),
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryRed, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.luxuryTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_left_2,
              color: AppColors.luxuryTextSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'error_loading_profile'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<AuthCubit>().getProfile();
            },
            child: Text('retry'.tr()),
          ),
        ],
      ),
    );
  }

  void _openLoyaltyScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoyaltyScreen()),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('logout_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().logout();
            },
            child: Text('logout'.tr()),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('language_arabic'.tr()),
              leading: const Icon(Iconsax.flag),
              onTap: () async {
                Navigator.pop(dialogContext);
                if (context.locale.languageCode == 'ar') return;
                await context.setLocale(const Locale('ar'));
                if (!context.mounted) return;
                context.read<AuthCubit>().updateLanguage('ar');
              },
            ),
            ListTile(
              title: Text('language_english'.tr()),
              leading: const Icon(Iconsax.flag),
              onTap: () async {
                Navigator.pop(dialogContext);
                if (context.locale.languageCode == 'en') return;
                await context.setLocale(const Locale('en'));
                if (!context.mounted) return;
                context.read<AuthCubit>().updateLanguage('en');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final url = Uri.parse('https://privacy-sepia-three.vercel.app/');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('cannot_open_link'.tr()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_opening_link'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_account'.tr()),
        content: Text('delete_account_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().deleteAccount();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('delete_account'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountErrorDialog(BuildContext context, String errorKey) {
    // Check if dialog is already showing to avoid multiple dialogs
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'delete_account_error'.tr(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
        content: Text(
          errorKey.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showInviteFriendsDialog(BuildContext context) {
    const appLink =
        'https://play.google.com/store/apps/details?id=com.company.kinetic';
    final shareText = '${'try_kinetic_app'.tr()}\n\n$appLink';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryRed, AppColors.primaryPink],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.share,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'share_app'.tr(),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'choose_share_platform'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.luxuryTextSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.close_circle),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.luxuryTextSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Share Options Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildShareAppIcon(
                      context,
                      iconWidget: const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        size: 28,
                        color: Colors.white,
                      ),
                      title: 'WhatsApp',
                      color: AppColors.primaryRed,
                      onTap: () async {
                        Navigator.pop(context);
                        final uri = Uri.parse(
                          'https://wa.me/?text=${Uri.encodeComponent(shareText)}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('cannot_open_whatsapp'.tr()),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    _buildShareAppIcon(
                      context,
                      iconWidget: const FaIcon(
                        FontAwesomeIcons.facebookMessenger,
                        size: 28,
                        color: Colors.white,
                      ),
                      title: 'Messenger',
                      color: AppColors.primaryRed,
                      onTap: () async {
                        Navigator.pop(context);
                        final uri = Uri.parse(
                          'https://m.me/share?text=${Uri.encodeComponent(shareText)}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('cannot_open_messenger'.tr()),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    _buildShareAppIcon(
                      context,
                      iconWidget: const FaIcon(
                        FontAwesomeIcons.facebook,
                        size: 28,
                        color: Colors.white,
                      ),
                      title: 'Facebook',
                      color: AppColors.primaryRed,
                      onTap: () async {
                        Navigator.pop(context);
                        final uri = Uri.parse(
                          'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(appLink)}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('cannot_open_facebook'.tr()),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    _buildShareAppIcon(
                      context,
                      iconWidget: const FaIcon(
                        FontAwesomeIcons.xTwitter,
                        size: 28,
                        color: Colors.white,
                      ),
                      title: 'X',
                      color: AppColors.primaryRed,
                      onTap: () async {
                        Navigator.pop(context);
                        final uri = Uri.parse(
                          'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText)}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('cannot_open_x'.tr())),
                            );
                          }
                        }
                      },
                    ),
                    _buildShareAppIcon(
                      context,
                      iconWidget: const FaIcon(
                        FontAwesomeIcons.telegram,
                        size: 28,
                        color: Colors.white,
                      ),
                      title: 'Telegram',
                      color: AppColors.primaryRed,
                      onTap: () async {
                        Navigator.pop(context);
                        final uri = Uri.parse(
                          'https://t.me/share/url?url=${Uri.encodeComponent(appLink)}&text=${Uri.encodeComponent('try_kinetic_app'.tr())}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('cannot_open_telegram'.tr()),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    _buildShareAppIcon(
                      context,
                      iconWidget: const Icon(
                        Iconsax.share,
                        size: 28,
                        color: Colors.white,
                      ),
                      title: 'other'.tr(),
                      color: AppColors.primaryRed,
                      onTap: () async {
                        Navigator.pop(context);
                        await Share.share(shareText);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareAppIcon(
    BuildContext context, {
    required Widget iconWidget,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryRed.withOpacity(0.1),
                AppColors.primaryPink.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryRed.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryRed, AppColors.primaryPink],
                  ),
                  shape: BoxShape.circle,
                ),
                child: iconWidget,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryRed,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
