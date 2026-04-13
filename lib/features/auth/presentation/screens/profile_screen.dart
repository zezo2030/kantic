import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
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
          }
        },
        builder: (context, state) {
          // Check if user is guest
          if (state is Guest) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/welcome',
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('login_required'.tr()),
                  backgroundColor: Colors.orange,
                ),
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is Authenticated) {
            return _buildProfileContent(context, state.user);
          } else {
            return _buildErrorContent(context);
          }
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, user) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.onPrimary,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Name
                Text(
                  user.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // Email
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),

                if (user.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.phone!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // User Information
          Text(
            'user_info'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow(context, 'roles'.tr(), user.roles.join(', ')),

                const SizedBox(height: 12),

                _buildInfoRow(
                  context,
                  'language'.tr(),
                  user.language.toUpperCase(),
                ),

                const SizedBox(height: 12),

                _buildInfoRow(
                  context,
                  'is_active'.tr(),
                  (user.isActive == true) ? 'yes'.tr() : 'no'.tr(),
                ),

                if (user.lastLoginAt != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    'last_login'.tr(),
                    _formatDate(user.lastLoginAt),
                  ),
                ],

                const SizedBox(height: 12),

                _buildInfoRow(
                  context,
                  'created_at'.tr(),
                  _formatDate(user.createdAt),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // My Bookings Entry
          CustomButton(
            text: 'my_bookings',
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
            onPressed: () {
              Navigator.pushNamed(context, '/my-bookings');
            },
          ),

          const SizedBox(height: 16),

          // School Booking Entry
          CustomButton(
            text: 'school_booking',
            icon: const Icon(Icons.event_available_outlined, size: 20),
            onPressed: () {
              Navigator.pushNamed(context, '/main');
            },
          ),

          const SizedBox(height: 16),

          // School Trips Entry
          CustomButton(
            text: 'school_trips_title',
            icon: const Icon(Icons.school_outlined, size: 20),
            onPressed: () {
              Navigator.pushNamed(context, '/school-trips');
            },
          ),

          const SizedBox(height: 24),

          // Logout Button
          CustomButton(
            text: 'logout',
            onPressed: () {
              _showLogoutDialog(context);
            },
            backgroundColor: theme.colorScheme.error,
            icon: const Icon(Icons.logout, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
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
          CustomButton(
            text: 'retry',
            onPressed: () {
              context.read<AuthCubit>().getProfile();
            },
          ),
        ],
      ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
