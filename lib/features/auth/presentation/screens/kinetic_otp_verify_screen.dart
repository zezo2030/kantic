import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart'
    as easy_localization;
import '../../../../core/widgets/custom_toast.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

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

class _KineticOtpVerifyScreenState extends State<KineticOtpVerifyScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _secondsLeft = 60;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Focus first field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  void _onOtpChanged(int index, String value) {
    // Handle paste or multiple characters
    if (value.length > 1) {
      // Take only the first character
      _otpControllers[index].text = value[0];
      _otpControllers[index].selection = TextSelection.collapsed(offset: 1);
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        // Move to next field
        Future.microtask(() {
          _focusNodes[index + 1].requestFocus();
        });
      } else {
        // Last field, unfocus
        Future.microtask(() {
          _focusNodes[index].unfocus();
          if (_otpCode.length == 6) {
            _verify();
          }
        });
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      Future.microtask(() {
        _focusNodes[index - 1].requestFocus();
      });
    }

    if (_hasError) {
      setState(() => _hasError = false);
    }
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
    // Reset timer
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
    return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
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
              // Clear OTP fields on error
              for (var controller in _otpControllers) {
                controller.clear();
              }
              _focusNodes[0].requestFocus();

              // Show beautiful toast for OTP errors
              final message = state.message.toLowerCase();
              if (message.contains('invalid') ||
                  message.contains('expired') ||
                  message.contains('otp') ||
                  message.contains('خطأ') ||
                  message.contains('غير صحيح') ||
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

            return Column(
              children: [
                // Header gradient with white logo
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFFE6003A), Color(0xFFFF2871)],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/imgs/kinetic.png',
                            height: 180,
                            color: Colors.white,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            easy_localization.tr('kinetic_your_ticket_to_fun'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Card area (overlapping slightly and filling downwards)
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -36),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/imgs/kinetic.png',
                                  height: 36,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              easy_localization.tr('one_step_left'),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: Color(0xFF6C6C6C),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Helper text
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                easy_localization.tr('verification_code'),
                                style: TextStyle(
                                  color: Color(0xFF8D8D8D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                easy_localization.tr(
                                  'enter_sms_verification_code',
                                ),
                                style: TextStyle(
                                  color: Color(0xFF9AA0A6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // OTP input fields
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
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
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                      letterSpacing: 0,
                                    ),
                                    cursorColor: const Color(0xFFE6003A),
                                    cursorWidth: 2,
                                    cursorRadius: const Radius.circular(1),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(1),
                                      TextInputFormatter.withFunction((
                                        oldValue,
                                        newValue,
                                      ) {
                                        // Handle paste of multiple digits
                                        if (newValue.text.length > 1) {
                                          final digits = newValue.text
                                              .replaceAll(
                                                RegExp(r'[^0-9]'),
                                                '',
                                              );
                                          if (digits.length >= 6) {
                                            // Fill all fields with pasted digits
                                            for (
                                              int i = 0;
                                              i < 6 && i < digits.length;
                                              i++
                                            ) {
                                              _otpControllers[i].text =
                                                  digits[i];
                                            }
                                            // Focus last field
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
                                            // Fill current and next fields
                                            int currentIndex = index;
                                            for (
                                              int i = 0;
                                              i < digits.length &&
                                                  currentIndex + i < 6;
                                              i++
                                            ) {
                                              _otpControllers[currentIndex + i]
                                                      .text =
                                                  digits[i];
                                            }
                                            final nextIndex =
                                                (currentIndex + digits.length)
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
                                      // Select all text when tapped
                                      _otpControllers[index]
                                          .selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset:
                                            _otpControllers[index].text.length,
                                      );
                                    },
                                    onSubmitted: (value) {
                                      if (value.isNotEmpty && index < 5) {
                                        _focusNodes[index + 1].requestFocus();
                                      }
                                    },
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: _hasError
                                          ? const Color(0xFFFFEBEE)
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
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: _hasError
                                              ? const Color(0xFFE6003A)
                                              : const Color(0xFFFF5CAB),
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: _hasError
                                              ? const Color(0xFFE6003A)
                                              : const Color(0xFFFF5CAB),
                                          width: 2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFFF6A00),
                                          width: 2.5,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE6003A),
                                          width: 2,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE6003A),
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

                            const SizedBox(height: 12),

                            // Timer or Resend button
                            if (_secondsLeft > 0)
                              Center(
                                child: Text(
                                  '${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: Color(0xFF4A4A4A),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
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
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: <Color>[
                                          Color(0xFFFF5CAB),
                                          Color(0xFFFF6A00),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF5CAB,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          easy_localization.tr(
                                            'resend_verification_code',
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Change phone info
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF5CAB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        easy_localization.tr(
                                          'want_to_edit_entered_number',
                                        ),
                                        style: TextStyle(
                                          color: Color(0xFF8D8D8D),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        widget.phone.startsWith('+')
                                            ? widget.phone
                                            : '+${widget.phone}',
                                        style: const TextStyle(
                                          color: Color(0xFFE6003A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Submit button
                            SizedBox(
                              height: 52,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: Ink(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: <Color>[
                                          Color(0xFFFF5CAB),
                                          Color(0xFFFF6A00),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: isLoading
                                          ? null
                                          : () {
                                              if (_otpCode.length == 6) {
                                                _verify();
                                              }
                                            },
                                      child: Center(
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                easy_localization.tr('login'),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
