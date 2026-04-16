import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as easy_localization;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/routes/app_route_generator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/saudi_phone_utils.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/language_switcher.dart';

class KineticLoginScreen extends StatefulWidget {
  const KineticLoginScreen({super.key});

  @override
  State<KineticLoginScreen> createState() => _KineticLoginScreenState();
}

class _KineticLoginScreenState extends State<KineticLoginScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscure = true;
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
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String _formatLoginError(String message) {
    final normalizedMessage = message.trim();
    final lowerMessage = normalizedMessage.toLowerCase();

    if (lowerMessage == 'invalid_credentials' ||
        normalizedMessage == 'invalid_credentials') {
      return 'invalid_credentials'.tr();
    }

    if (lowerMessage == 'wrong_password' ||
        lowerMessage == 'phone_not_found' ||
        lowerMessage == 'user_not_found' ||
        lowerMessage == 'account_inactive') {
      return lowerMessage.tr();
    }

    if (normalizedMessage.contains('DioException') ||
        normalizedMessage.contains('Exception:') ||
        normalizedMessage.contains('bad response') ||
        normalizedMessage.contains('status code') ||
        normalizedMessage.contains('401')) {
      return 'wrong_password'.tr();
    }

    if (lowerMessage.contains('invalid credentials')) {
      return 'invalid_credentials'.tr();
    } else if (lowerMessage.contains('wrong password') ||
        lowerMessage.contains('incorrect password') ||
        lowerMessage.contains('unauthorized')) {
      return 'wrong_password'.tr();
    } else if (lowerMessage.contains('phone') &&
        (lowerMessage.contains('not found') ||
            lowerMessage.contains('not registered'))) {
      return 'phone_not_found'.tr();
    } else if (lowerMessage.contains('inactive')) {
      return 'account_inactive'.tr();
    }

    if (lowerMessage.contains('invalid')) {
      return 'invalid_credentials'.tr();
    }

    return 'invalid_credentials'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (!mounted) return;
            if (state is Authenticated) {
              Navigator.pushReplacementNamed(context, '/main');
            } else if (state is AuthError) {
              final errorMessage = _formatLoginError(state.message);
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
                      Expanded(child: Text(errorMessage)),
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
                    painter: _LoginWavePainter(),
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
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0x0F000000),
                                              blurRadius: 12,
                                              offset: const Offset(0, 2),
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
                                      'welcome_back'.tr(),
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
                                      'login_subtitle'.tr(),
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

                                _StyledPhoneField(
                                      controller: _phoneController,
                                      focusNode: _phoneFocus,
                                      nextFocus: _passwordFocus,
                                    )
                                    .animate()
                                    .fadeIn(duration: 600.ms, delay: 400.ms)
                                    .slideY(
                                      begin: 0.15,
                                      end: 0,
                                      duration: 600.ms,
                                      delay: 400.ms,
                                    ),

                                const SizedBox(height: 16),

                                _StyledPasswordField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      obscure: _obscure,
                                      onToggleObscure: () =>
                                          setState(() => _obscure = !_obscure),
                                    )
                                    .animate()
                                    .fadeIn(duration: 600.ms, delay: 500.ms)
                                    .slideY(
                                      begin: 0.15,
                                      end: 0,
                                      duration: 600.ms,
                                      delay: 500.ms,
                                    ),

                                const SizedBox(height: 8),

                                Align(
                                    alignment: AlignmentDirectional.centerStart,
                                  child: TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.forgotPasswordKinetic,
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'forgot_password'.tr(),
                                      style: TextStyle(
                                        color: AppColors.primaryRed,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'MontserratArabic',
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(
                                  duration: 500.ms,
                                  delay: 550.ms,
                                ),

                                const SizedBox(height: 20),

                                _LoginButton(
                                      isLoading: isLoading,
                                      onTap: () {
                                        if (_formKey.currentState!.validate()) {
                                          context.read<AuthCubit>().login(
                                            phone: SaudiPhoneUtils.toE164(
                                              _phoneController.text,
                                            ),
                                            password: _passwordController.text,
                                          );
                                        }
                                      },
                                    )
                                    .animate()
                                    .fadeIn(duration: 600.ms, delay: 600.ms)
                                    .slideY(
                                      begin: 0.15,
                                      end: 0,
                                      duration: 600.ms,
                                      delay: 600.ms,
                                    ),

                                const SizedBox(height: 24),

                                _RegisterLink().animate().fadeIn(
                                  duration: 600.ms,
                                  delay: 700.ms,
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
                              style: TextStyle(
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
    );
  }
}

class _StyledPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode nextFocus;

  const _StyledPhoneField({
    required this.controller,
    required this.focusNode,
    required this.nextFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => nextFocus.requestFocus(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
          fontFamily: 'MontserratArabic',
        ),
        decoration: InputDecoration(
          hintText: 'saudi_mobile_hint'.tr(),
          hintStyle: TextStyle(
            color: const Color(0xFFC0C0C0),
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: 'MontserratArabic',
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsetsDirectional.only(
            start: 4,
            end: 16,
            top: 16,
            bottom: 16,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '+966',
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.2,
                        fontFamily: 'MontserratArabic',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFE8DDD4),
                  ),
                ],
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 108,
            maxHeight: 56,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE8DDD4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE8DDD4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.primaryRed,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.errorColor, width: 1.5),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'kinetic_mobile_number_required'.tr();
          }
          final e164 = SaudiPhoneUtils.toE164(value);
          if (!SaudiPhoneUtils.isValidSaudiMobile(e164)) {
            return 'saudi_mobile_invalid'.tr();
          }
          return null;
        },
      ),
    );
  }
}

class _StyledPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final VoidCallback onToggleObscure;

  const _StyledPasswordField({
    required this.controller,
    required this.focusNode,
    required this.obscure,
    required this.onToggleObscure,
  });

  @override
  State<_StyledPasswordField> createState() => _StyledPasswordFieldState();
}

class _StyledPasswordFieldState extends State<_StyledPasswordField> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _hasFocus = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: widget.obscure,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A1A),
        fontFamily: 'MontserratArabic',
      ),
      decoration: InputDecoration(
        hintText: 'complete_registration_password_hint'.tr(),
        hintStyle: TextStyle(
          color: const Color(0xFFC0C0C0),
          fontSize: 15,
          fontWeight: FontWeight.w400,
          fontFamily: 'MontserratArabic',
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(
            _hasFocus ? Icons.lock : Icons.lock_outline,
            size: 22,
            color: _hasFocus ? AppColors.primaryRed : const Color(0xFFB0A8A0),
          ),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            onPressed: widget.onToggleObscure,
            icon: Icon(
              widget.obscure ? Icons.visibility_off : Icons.visibility,
              size: 22,
              color: const Color(0xFFB0A8A0),
            ),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8DDD4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8DDD4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.errorColor, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'complete_registration_password_required'.tr();
        }
        if (value.length < 6) {
          return 'complete_registration_password_too_short'.tr();
        }
        return null;
      },
    );
  }
}

class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _LoginButton({required this.isLoading, required this.onTap});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
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
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x4DFF5E00),
                      offset: const Offset(0, 8),
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
                        'login'.tr(),
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

class _RegisterLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'no_account'.tr(),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontFamily: 'MontserratArabic',
          ),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.otpLoginKinetic),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'register'.tr(),
            style: TextStyle(
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

class _LoginWavePainter extends CustomPainter {
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
