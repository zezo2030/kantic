import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as easy_localization;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/routes/app_route_generator.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/language_switcher.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 12000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFFBF5),
                          Color(0xFFFFF3E8),
                          Color(0xFFFFEAD8),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                _ConfettiParticles(
                  controller: _particleController,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),

                Positioned(
                  left: -32,
                  right: -32,
                  bottom: -60,
                  child: CustomPaint(
                    size: Size(screenWidth + 64, 220),
                    painter: _DualWavePainter(),
                  ),
                ),

                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [const LanguageSwitcher()]
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 200.ms)
                                  .slideY(
                                    begin: -0.3,
                                    end: 0,
                                    duration: 600.ms,
                                    delay: 200.ms,
                                    curve: Curves.easeOutQuart,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28.0,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 60,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(height: screenHeight * 0.08),

                                    AnimatedBuilder(
                                          animation: _floatController,
                                          builder: (context, child) {
                                            final offset =
                                                sin(
                                                  _floatController.value *
                                                      pi *
                                                      2,
                                                ) *
                                                6;
                                            return Transform.translate(
                                              offset: Offset(0, offset),
                                              child: child,
                                            );
                                          },
                                          child: Image.asset(
                                            'assets/imgs/kinetic.png',
                                            width: 170,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 800.ms,
                                          curve: Curves.easeOutQuart,
                                        )
                                        .scale(
                                          begin: const Offset(0.85, 0.85),
                                          end: const Offset(1, 1),
                                          duration: 800.ms,
                                          curve: Curves.easeOutQuart,
                                        ),

                                    const SizedBox(height: 20),

                                    Column(
                                          children: [
                                            Text(
                                              'welcome_tagline'.tr(),
                                              style: theme
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primaryRed,
                                                    height: 1.3,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'welcome_subtitle'.tr(),
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                    height: 1.5,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 700.ms,
                                          delay: 300.ms,
                                          curve: Curves.easeOutQuart,
                                        )
                                        .slideY(
                                          begin: 0.15,
                                          end: 0,
                                          duration: 700.ms,
                                          delay: 300.ms,
                                          curve: Curves.easeOutQuart,
                                        ),

                                    SizedBox(height: screenHeight * 0.06),

                                    _PrimaryButton(
                                          text: 'login'.tr(),
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            AppRoutes.login,
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 600.ms,
                                          delay: 500.ms,
                                          curve: Curves.easeOutQuart,
                                        )
                                        .slideY(
                                          begin: 0.2,
                                          end: 0,
                                          duration: 600.ms,
                                          delay: 500.ms,
                                          curve: Curves.easeOutQuart,
                                        ),

                                    const SizedBox(height: 16),

                                    _SecondaryButton(
                                          text: 'register'.tr(),
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            AppRoutes.otpLoginKinetic,
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 600.ms,
                                          delay: 650.ms,
                                          curve: Curves.easeOutQuart,
                                        )
                                        .slideY(
                                          begin: 0.2,
                                          end: 0,
                                          duration: 600.ms,
                                          delay: 650.ms,
                                          curve: Curves.easeOutQuart,
                                        ),

                                    const SizedBox(height: 12),

                                    _GhostButton(
                                          text: 'continue_as_guest'.tr(),
                                          onTap: () {
                                            context
                                                .read<AuthCubit>()
                                                .enterAsGuest();
                                          },
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 600.ms,
                                          delay: 800.ms,
                                          curve: Curves.easeOutQuart,
                                        )
                                        .slideY(
                                          begin: 0.2,
                                          end: 0,
                                          duration: 600.ms,
                                          delay: 800.ms,
                                          curve: Curves.easeOutQuart,
                                        ),

                                    const SizedBox(height: 48),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

class _PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _PrimaryButton({required this.text, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x4DFF5E00),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                    ),
                    BoxShadow(
                      color: const Color(0x26FF8A00),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'MontserratArabic',
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _SecondaryButton({required this.text, required this.onTap});

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0x40FF5E00),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0A000000),
                      offset: const Offset(0, 4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'MontserratArabic',
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GhostButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _GhostButton({required this.text, required this.onTap});

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'MontserratArabic',
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiParticles extends StatelessWidget {
  final AnimationController controller;
  final double screenWidth;
  final double screenHeight;

  const _ConfettiParticles({
    required this.controller,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(screenWidth, screenHeight),
          painter: _ConfettiPainter(
            progress: controller.value,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final double screenWidth;
  final double screenHeight;

  static final _rng = Random(42);
  static final _particles = List.generate(
    18,
    (i) => {
      'x': _rng.nextDouble(),
      'y': _rng.nextDouble(),
      'size': 3.0 + _rng.nextDouble() * 6.0,
      'speed': 0.15 + _rng.nextDouble() * 0.35,
      'phase': _rng.nextDouble() * 2 * pi,
      'colorIndex': _rng.nextInt(4),
    },
  );

  static const _colors = [
    Color(0x30FF8A00),
    Color(0x28FF5E00),
    Color(0x20E10000),
    Color(0x25FFB74D),
  ];

  _ConfettiPainter({
    required this.progress,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final baseX = p['x'] as double;
      final baseY = p['y'] as double;
      final particleSize = p['size'] as double;
      final speed = p['speed'] as double;
      final phase = p['phase'] as double;
      final colorIndex = p['colorIndex'] as int;

      final t = (progress * speed + baseY) % 1.0;
      final y = t * screenHeight;
      final x = baseX * screenWidth + sin(t * 4 * pi + phase) * 20;

      final opacity = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.7;
      final color = Color.fromARGB(
        (opacity * 255).round(),
        (_colors[colorIndex].r * 255).round(),
        (_colors[colorIndex].g * 255).round(),
        (_colors[colorIndex].b * 255).round(),
      );

      canvas.drawCircle(Offset(x, y), particleSize, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

class _DualWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final backWavePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFB74D), Color(0xFFFF8A00)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final backPath = Path();
    backPath.moveTo(0, h * 0.45);
    backPath.quadraticBezierTo(w * 0.15, h * 0.25, w * 0.35, h * 0.38);
    backPath.quadraticBezierTo(w * 0.55, h * 0.52, w * 0.75, h * 0.35);
    backPath.quadraticBezierTo(w * 0.90, h * 0.24, w, h * 0.38);
    backPath.lineTo(w, h);
    backPath.lineTo(0, h);
    backPath.close();
    canvas.drawPath(backPath, backWavePaint);

    final frontWavePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8A00), Color(0xFFFF5E00), Color(0xFFE10000)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final frontPath = Path();
    frontPath.moveTo(0, h * 0.55);
    frontPath.quadraticBezierTo(w * 0.20, h * 0.35, w * 0.40, h * 0.48);
    frontPath.quadraticBezierTo(w * 0.60, h * 0.62, w * 0.80, h * 0.45);
    frontPath.quadraticBezierTo(w * 0.92, h * 0.36, w, h * 0.50);
    frontPath.lineTo(w, h);
    frontPath.lineTo(0, h);
    frontPath.close();
    canvas.drawPath(frontPath, frontWavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
