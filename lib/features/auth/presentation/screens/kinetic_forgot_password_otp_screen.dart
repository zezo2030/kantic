import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart'
    as easy_localization;
import '../../../../core/routes/app_route_generator.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/otp_input_field.dart';

/// Step after phone: enter WhatsApp OTP, then go to new-password screen.
class KineticForgotPasswordOtpScreen extends StatefulWidget {
  final String phone;

  const KineticForgotPasswordOtpScreen({super.key, required this.phone});

  @override
  State<KineticForgotPasswordOtpScreen> createState() =>
      _KineticForgotPasswordOtpScreenState();
}

class _KineticForgotPasswordOtpScreenState
    extends State<KineticForgotPasswordOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _resendTimer;
  int _resendSecondsLeft = 0;
  /// Only handle [ForgotPasswordOtpSent] / [AuthError] from our resend, not from other routes using the same cubit.
  bool _awaitingSendOtpResponse = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsLeft = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSecondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendSecondsLeft = 0);
      } else {
        if (mounted) setState(() => _resendSecondsLeft -= 1);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  void _verifyAndContinue() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(easy_localization.tr('otp_invalid'))),
      );
      return;
    }
    // Let PinCode finish focus/animation before navigating (avoids deactivated context).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.forgotPasswordNewPasswordKinetic,
        arguments: <String, dynamic>{
          'phone': widget.phone,
          'otp': otp,
        },
      );
    });
  }

  void _resend() {
    if (_resendSecondsLeft > 0) return;
    if (!mounted) return;
    final String lang = Localizations.localeOf(context).languageCode;
    setState(() => _awaitingSendOtpResponse = true);
    context.read<AuthCubit>().forgotPasswordSendOtp(
          phone: widget.phone,
          language: lang,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: BlocConsumer<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              (current is ForgotPasswordOtpSent ||
                  current is AuthError) &&
              _awaitingSendOtpResponse,
          listener: (context, state) {
            if (!context.mounted) return;
            if (state is ForgotPasswordOtpSent) {
              if (mounted) {
                setState(() => _awaitingSendOtpResponse = false);
              }
              _startResendCooldown();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    easy_localization.tr('forgot_password_otp_resent'),
                  ),
                ),
              );
            } else if (state is AuthError) {
              if (mounted) {
                setState(() => _awaitingSendOtpResponse = false);
              }
              final String text = state.message == 'operation_failed'
                  ? easy_localization.tr('operation_failed')
                  : state.message;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(text)),
              );
            }
          },
          builder: (context, state) {
            final bool isLoading = state is AuthLoading;
            final double bottomInset = MediaQuery.paddingOf(context).bottom;

            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.sizeOf(context).height * 0.22,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Color(0xFFE6003A),
                            Color(0xFFFF2871),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        24,
                        16,
                        32 + bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            easy_localization.tr('forgot_password_otp_title'),
                            style: const TextStyle(
                              color: Color(0xFF2B2B2B),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            easy_localization.tr(
                              'forgot_password_otp_subtitle',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF9AA0A6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          OtpInputField(
                            controller: _otpController,
                            onCompleted: (_) => _verifyAndContinue(),
                            onChanged: (_) => setState(() {}),
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: isLoading || _resendSecondsLeft > 0
                                  ? null
                                  : _resend,
                              child: Text(
                                _resendSecondsLeft > 0
                                    ? '${easy_localization.tr('send_otp')} ($_resendSecondsLeft)'
                                    : easy_localization.tr('send_otp'),
                                style: const TextStyle(
                                  color: Color(0xFFE6003A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                    onTap: isLoading ? null : _verifyAndContinue,
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
                                              easy_localization.tr(
                                                'forgot_password_verify_code',
                                              ),
                                              style: const TextStyle(
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
