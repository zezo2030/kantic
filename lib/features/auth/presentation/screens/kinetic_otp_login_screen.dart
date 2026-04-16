import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as easy_localization;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/routes/app_route_generator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/saudi_phone_utils.dart';
import '../widgets/saudi_phone_text_form_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/language_switcher.dart';

class KineticOtpLoginScreen extends StatefulWidget {
  const KineticOtpLoginScreen({super.key});

  @override
  State<KineticOtpLoginScreen> createState() => _KineticOtpLoginScreenState();
}

class _KineticOtpLoginScreenState extends State<KineticOtpLoginScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _localPhoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _localPhoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is OtpSent) {
              Navigator.pushNamed(
                context,
                '/otp-verify-kinetic',
                arguments: <String, dynamic>{
                  'phone': state.phone,
                  'isRegistration': false,
                },
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: AppColors.errorColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          builder: (context, state) {
            final bool isLoading = state is AuthLoading;

            return Stack(
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

                Positioned(
                  left: -24,
                  right: -24,
                  bottom: -40,
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width + 48, 160),
                    painter: _RegisterWavePainter(),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child:
                            Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const LanguageSwitcher(),
                                    IconButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x0F000000),
                                              blurRadius: 12,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward,
                                          size: 20,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                .animate()
                                .fadeIn(duration: 500.ms)
                                .slideY(begin: -0.2, end: 0, duration: 500.ms),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: screenHeight * 0.04),

                                AnimatedBuilder(
                                      animation: _floatController,
                                      builder: (context, child) {
                                        final offset =
                                            sin(
                                              _floatController.value * pi * 2,
                                            ) *
                                            5;
                                        return Transform.translate(
                                          offset: Offset(0, offset),
                                          child: child,
                                        );
                                      },
                                      child: Center(
                                        child: Image.asset(
                                          'assets/imgs/kinetic.png',
                                          height: 100,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: 700.ms)
                                    .scale(
                                      begin: const Offset(0.88, 0.88),
                                      end: const Offset(1, 1),
                                      duration: 700.ms,
                                      curve: Curves.easeOutQuart,
                                    ),

                                const SizedBox(height: 24),

                                Text(
                                      'create_account'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                            height: 1.2,
                                          ),
                                      textAlign: TextAlign.center,
                                    )
                                    .animate()
                                    .fadeIn(duration: 600.ms, delay: 200.ms)
                                    .slideY(
                                      begin: 0.12,
                                      end: 0,
                                      duration: 600.ms,
                                      delay: 200.ms,
                                    ),

                                const SizedBox(height: 6),

                                Text(
                                      'register_subtitle'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                      textAlign: TextAlign.center,
                                    )
                                    .animate()
                                    .fadeIn(duration: 600.ms, delay: 300.ms)
                                    .slideY(
                                      begin: 0.12,
                                      end: 0,
                                      duration: 600.ms,
                                      delay: 300.ms,
                                    ),

                                SizedBox(height: screenHeight * 0.04),

                                SaudiPhoneTextFormField(
                                      controller: _localPhoneController,
                                      focusNode: _phoneFocus,
                                      hintText: easy_localization.tr(
                                        'saudi_mobile_hint',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return easy_localization.tr(
                                            'kinetic_mobile_number_required',
                                          );
                                        }
                                        final e164 = SaudiPhoneUtils.toE164(
                                          value,
                                        );
                                        if (!SaudiPhoneUtils.isValidSaudiMobile(
                                          e164,
                                        )) {
                                          return easy_localization.tr(
                                            'saudi_mobile_invalid',
                                          );
                                        }
                                        return null;
                                      },
                                    )
                                    .animate()
                                    .fadeIn(duration: 600.ms, delay: 400.ms)
                                    .slideY(
                                      begin: 0.15,
                                      end: 0,
                                      duration: 600.ms,
                                      delay: 400.ms,
                                    ),

                                const SizedBox(height: 24),

                                _CreateAccountButton(
                                      isLoading: isLoading,
                                      onTap: () {
                                        if (_formKey.currentState!.validate()) {
                                          final String phone =
                                              SaudiPhoneUtils.toE164(
                                                _localPhoneController.text,
                                              );
                                          context.read<AuthCubit>().sendOtp(
                                            phone: phone,
                                          );
                                        }
                                      },
                                    )
                                    .animate()
                                    .fadeIn(duration: 600.ms, delay: 500.ms)
                                    .slideY(
                                      begin: 0.15,
                                      end: 0,
                                      duration: 600.ms,
                                      delay: 500.ms,
                                    ),

                                const SizedBox(height: 24),

                                _LoginLink().animate().fadeIn(
                                  duration: 600.ms,
                                  delay: 600.ms,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isLoading)
                  Container(
                    color: const Color(0x40000000),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryRed,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'loading'.tr(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'MontserratArabic',
                              ),
                            ),
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
    );
  }
}

class _CreateAccountButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _CreateAccountButton({required this.isLoading, required this.onTap});

  @override
  State<_CreateAccountButton> createState() => _CreateAccountButtonState();
}

class _CreateAccountButtonState extends State<_CreateAccountButton>
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
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
        onTapDown: widget.isLoading ? null : (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4DFF5E00),
                      offset: Offset(0, 8),
                      blurRadius: 24,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'create_account'.tr(),
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

class _LoginLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'have_account'.tr(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontFamily: 'MontserratArabic',
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'login'.tr(),
            style: const TextStyle(
              color: AppColors.primaryRed,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'MontserratArabic',
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final backPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFB74D), Color(0xFFFF8A00)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final backPath = Path();
    backPath.moveTo(0, h * 0.5);
    backPath.quadraticBezierTo(w * 0.2, h * 0.3, w * 0.45, h * 0.42);
    backPath.quadraticBezierTo(w * 0.7, h * 0.55, w * 0.85, h * 0.38);
    backPath.quadraticBezierTo(w * 0.95, h * 0.3, w, h * 0.42);
    backPath.lineTo(w, h);
    backPath.lineTo(0, h);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    final frontPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8A00), Color(0xFFFF5E00), Color(0xFFE10000)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final frontPath = Path();
    frontPath.moveTo(0, h * 0.6);
    frontPath.quadraticBezierTo(w * 0.25, h * 0.42, w * 0.5, h * 0.55);
    frontPath.quadraticBezierTo(w * 0.75, h * 0.68, w * 0.9, h * 0.5);
    frontPath.quadraticBezierTo(w * 0.97, h * 0.42, w, h * 0.55);
    frontPath.lineTo(w, h);
    frontPath.lineTo(0, h);
    frontPath.close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
