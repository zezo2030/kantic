import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as easy_localization;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class KineticOtpVerifyScreen extends StatefulWidget {
  final String phone;
  final bool isRegistration;

  const KineticOtpVerifyScreen({
    super.key,
    required this.phone,
    this.isRegistration = false,
  });

  @override
  State<KineticOtpVerifyScreen> createState() => _KineticOtpVerifyScreenState();
}

class _KineticOtpVerifyScreenState extends State<KineticOtpVerifyScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _secondsLeft = 60;
  bool _hasError = false;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat(reverse: true);
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      _otpControllers[index].text = value[0];
      _otpControllers[index].selection = TextSelection.collapsed(offset: 1);
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        Future.microtask(() => _focusNodes[index + 1].requestFocus());
      } else {
        Future.microtask(() {
          _focusNodes[index].unfocus();
          if (_otpCode.length == 6) _verify();
        });
      }
    } else if (value.isEmpty && index > 0) {
      Future.microtask(() => _focusNodes[index - 1].requestFocus());
    }

    if (_hasError) setState(() => _hasError = false);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  void _resendOtp() {
    if (widget.isRegistration) {
      context.read<AuthCubit>().registerSendOtp(phone: widget.phone);
    } else {
      context.read<AuthCubit>().sendOtp(phone: widget.phone);
    }
    setState(() => _secondsLeft = 60);
    _startTimer();
  }

  void _verify() {
    final otp = _otpCode;
    if (otp.length != 6) return;

    if (widget.isRegistration) {
      context.read<AuthCubit>().registerVerifyOtp(
        phone: widget.phone,
        otp: otp,
      );
    } else {
      context.read<AuthCubit>().verifyOtp(phone: widget.phone, otp: otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is RegistrationIncomplete) {
              Navigator.pushReplacementNamed(
                context,
                '/complete-registration',
                arguments: {'phone': state.phone},
              );
            } else if (state is OtpVerified) {
              final bool isNewUser = state.authResponse.isNewUser == true;
              if (isNewUser) {
                Navigator.pushReplacementNamed(
                  context,
                  '/complete-registration',
                  arguments: {'phone': widget.phone},
                );
              } else {
                Navigator.pushReplacementNamed(context, '/main');
              }
            } else if (state is RegisterSuccess) {
              Navigator.pushReplacementNamed(context, '/main');
            } else if (state is AuthError) {
              setState(() => _hasError = true);
              for (var controller in _otpControllers) {
                controller.clear();
              }
              _focusNodes[0].requestFocus();

              final message = state.message.toLowerCase();
              if (message.contains('invalid') ||
                  message.contains('expired') ||
                  message.contains('otp') ||
                  message.contains('wrong') ||
                  message.contains('incorrect')) {
                CustomToast.showOtpError(
                  context,
                  message: easy_localization.tr('incorrect_number'),
                  onResend: _resendOtp,
                );
              } else {
                CustomToast.showError(
                  context,
                  message: easy_localization.tr('incorrect_number'),
                );
              }
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
                    painter: _OtpVerifyWavePainter(),
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
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: screenHeight * 0.03),

                              AnimatedBuilder(
                                    animation: _floatController,
                                    builder: (context, child) {
                                      final offset =
                                          sin(_floatController.value * pi * 2) *
                                          5;
                                      return Transform.translate(
                                        offset: Offset(0, offset),
                                        child: child,
                                      );
                                    },
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFF3E8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.sms_rounded,
                                          size: 40,
                                          color: AppColors.primaryRed,
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 700.ms)
                                  .scale(
                                    begin: const Offset(0.85, 0.85),
                                    end: const Offset(1, 1),
                                    duration: 700.ms,
                                    curve: Curves.easeOutQuart,
                                  ),

                              const SizedBox(height: 24),

                              Text(
                                    easy_localization.tr('one_step_left'),
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
                                easy_localization.tr(
                                  'enter_sms_verification_code',
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                textAlign: TextAlign.center,
                              ).animate().fadeIn(
                                duration: 600.ms,
                                delay: 300.ms,
                              ),

                              SizedBox(height: screenHeight * 0.03),

                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(6, (index) {
                                    final isActive =
                                        _focusNodes[index].hasFocus;
                                    return Container(
                                      margin: EdgeInsets.only(
                                        right: index < 5 ? 8 : 0,
                                      ),
                                      width: 48,
                                      height: 56,
                                      child: TextField(
                                        controller: _otpControllers[index],
                                        focusNode: _focusNodes[index],
                                        enabled: !isLoading,
                                        autofocus: index == 0,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        maxLength: 1,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: _hasError
                                              ? AppColors.errorColor
                                              : const Color(0xFF1A1A1A),
                                          letterSpacing: 0,
                                          fontFamily: 'MontserratArabic',
                                        ),
                                        cursorColor: AppColors.primaryRed,
                                        cursorWidth: 2,
                                        cursorRadius: const Radius.circular(1),
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(1),
                                          TextInputFormatter.withFunction((
                                            oldValue,
                                            newValue,
                                          ) {
                                            if (newValue.text.length > 1) {
                                              final digits = newValue.text
                                                  .replaceAll(
                                                    RegExp(r'[^0-9]'),
                                                    '',
                                                  );
                                              if (digits.length >= 6) {
                                                for (
                                                  int i = 0;
                                                  i < 6 && i < digits.length;
                                                  i++
                                                ) {
                                                  _otpControllers[i].text =
                                                      digits[i];
                                                }
                                                Future.microtask(() {
                                                  _focusNodes[5].requestFocus();
                                                  if (digits.length >= 6) {
                                                    _verify();
                                                  }
                                                });
                                                return TextEditingValue(
                                                  text: digits[0],
                                                  selection:
                                                      TextSelection.collapsed(
                                                        offset: 1,
                                                      ),
                                                );
                                              } else if (digits.isNotEmpty) {
                                                int currentIndex = index;
                                                for (
                                                  int i = 0;
                                                  i < digits.length &&
                                                      currentIndex + i < 6;
                                                  i++
                                                ) {
                                                  _otpControllers[currentIndex +
                                                              i]
                                                          .text =
                                                      digits[i];
                                                }
                                                final nextIndex =
                                                    (currentIndex +
                                                            digits.length)
                                                        .clamp(0, 5);
                                                Future.microtask(() {
                                                  _focusNodes[nextIndex]
                                                      .requestFocus();
                                                });
                                                return TextEditingValue(
                                                  text: digits[0],
                                                  selection:
                                                      TextSelection.collapsed(
                                                        offset: 1,
                                                      ),
                                                );
                                              }
                                            }
                                            return newValue;
                                          }),
                                        ],
                                        textInputAction: index < 5
                                            ? TextInputAction.next
                                            : TextInputAction.done,
                                        onTap: () {
                                          _otpControllers[index]
                                              .selection = TextSelection(
                                            baseOffset: 0,
                                            extentOffset: _otpControllers[index]
                                                .text
                                                .length,
                                          );
                                        },
                                        onSubmitted: (value) {
                                          if (value.isNotEmpty && index < 5) {
                                            _focusNodes[index + 1]
                                                .requestFocus();
                                          }
                                        },
                                        decoration: InputDecoration(
                                          counterText: '',
                                          filled: true,
                                          fillColor: _hasError
                                              ? const Color(0x1AFFEBEE)
                                              : isActive
                                              ? const Color(0xFFFFF3E8)
                                              : Colors.white,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 16,
                                                horizontal: 0,
                                              ),
                                          isDense: true,
                                          hintText: '',
                                          hintStyle: const TextStyle(
                                            color: Colors.transparent,
                                            fontSize: 0,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: _hasError
                                                  ? AppColors.errorColor
                                                  : const Color(0xFFE8DDD4),
                                              width: 1.5,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: _hasError
                                                  ? AppColors.errorColor
                                                  : const Color(0xFFE8DDD4),
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.primaryRed,
                                              width: 2,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.errorColor,
                                              width: 2,
                                            ),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: AppColors.errorColor,
                                                  width: 2.5,
                                                ),
                                              ),
                                        ),
                                        onChanged: (value) =>
                                            _onOtpChanged(index, value),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ).animate().fadeIn(
                              duration: 600.ms,
                              delay: 400.ms,
                            ),

                              const SizedBox(height: 16),

                              if (_secondsLeft > 0)
                                Center(
                                  child: Text(
                                    '${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'MontserratArabic',
                                    ),
                                  ),
                                )
                              else
                                Center(
                                  child: GestureDetector(
                                    onTap: _resendOtp,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E8),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.refresh_rounded,
                                            color: AppColors.primaryRed,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            easy_localization.tr(
                                              'resend_verification_code',
                                            ),
                                            style: const TextStyle(
                                              color: AppColors.primaryRed,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'MontserratArabic',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(
                                  duration: 500.ms,
                                  delay: 500.ms,
                                ),

                              const SizedBox(height: 20),

                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8F2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFF3E8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.phone_android_rounded,
                                        color: AppColors.primaryRed,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            easy_localization.tr(
                                              'want_to_edit_entered_number',
                                            ),
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'MontserratArabic',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.phone.startsWith('+')
                                                ? widget.phone
                                                : '+${widget.phone}',
                                            style: const TextStyle(
                                              color: AppColors.primaryRed,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'MontserratArabic',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(
                                duration: 500.ms,
                                delay: 550.ms,
                              ),

                              const SizedBox(height: 24),

                              _VerifyButton(
                                    isLoading: isLoading,
                                    isRegistration: widget.isRegistration,
                                    onTap: () {
                                      if (_otpCode.length == 6) _verify();
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

                              const SizedBox(height: 48),
                            ],
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

class _VerifyButton extends StatefulWidget {
  final bool isLoading;
  final bool isRegistration;
  final VoidCallback onTap;

  const _VerifyButton({
    required this.isLoading,
    required this.isRegistration,
    required this.onTap,
  });

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton>
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
                        widget.isRegistration
                            ? easy_localization.tr('register')
                            : easy_localization.tr('login'),
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

class _OtpVerifyWavePainter extends CustomPainter {
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
