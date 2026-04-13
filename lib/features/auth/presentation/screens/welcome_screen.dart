import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as easy_localization;
import '../../../../core/routes/app_route_generator.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated || state is Guest) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/main');
            });
          }
        },
        builder: (context, state) {
          // Check if already authenticated or guest when screen is built
          if (state is Authenticated || state is Guest) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/main');
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(
              children: [
                // White background
                Positioned.fill(
                  child: Container(color: theme.colorScheme.surface),
                ),

                // Bottom large red/orange wave
                Positioned(
                  left: -24,
                  right: -24,
                  bottom: -80,
                  child: _BottomWave(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryOrange, AppColors.primaryRed],
                    ),
                    height: 260,
                  ),
                ),

                // Removed purple overlay per new design

                // Content column
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 90),
                        // Logo - Centered
                        Center(
                          child: Image.asset(
                            'assets/imgs/kinetic.png',
                            width: 160,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Primary Login button
                        _GradientButton(
                          text: 'login'.tr(),
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.login),
                          gradient: AppColors.primaryGradient,
                        ),

                        const SizedBox(height: 24),

                        // Register button (white with shadow)
                        _OutlinedSoftButton(
                          text: 'register'.tr(),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.otpLoginKinetic,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Continue as Guest button
                        _OutlinedSoftButton(
                          text: 'continue_as_guest'.tr(),
                          onTap: () {
                            context.read<AuthCubit>().enterAsGuest();
                          },
                        ),

                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final LinearGradient gradient;

  const _GradientButton({
    required this.text,
    required this.onTap,
    required this.gradient,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.70; // 70% of screen width

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) => _animationController.reverse(),
          onTapCancel: () => _animationController.reverse(),
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(40),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: buttonWidth,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6A00).withOpacity(0.25),
                        offset: const Offset(0, 12),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OutlinedSoftButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _OutlinedSoftButton({required this.text, required this.onTap});

  @override
  State<_OutlinedSoftButton> createState() => _OutlinedSoftButtonState();
}

class _OutlinedSoftButtonState extends State<_OutlinedSoftButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.70; // 70% of screen width

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) => _animationController.reverse(),
          onTapCancel: () => _animationController.reverse(),
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(40),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: buttonWidth,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 20,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Removed guest pill button per latest design

class _BottomWave extends StatelessWidget {
  final LinearGradient gradient;
  final double height;

  const _BottomWave({required this.gradient, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: height,
        decoration: BoxDecoration(gradient: gradient),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.25);
    path.quadraticBezierTo(
      size.width * 0.10,
      size.height * 0.05,
      size.width * 0.35,
      size.height * 0.18,
    );
    path.quadraticBezierTo(
      size.width * 0.60,
      size.height * 0.35,
      size.width * 0.75,
      size.height * 0.22,
    );
    path.quadraticBezierTo(
      size.width * 0.92,
      size.height * 0.12,
      size.width,
      size.height * 0.26,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Removed _RoundedBlob widget (no longer used after design update)
