import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/otp_input_field.dart';
import '../widgets/loading_overlay.dart';
import '../../../../core/widgets/custom_toast.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String phone;
  final bool isRegistration;

  const OtpVerifyScreen({
    super.key,
    required this.phone,
    this.isRegistration = false,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('verify_otp'.tr()), centerTitle: true),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {

          if (state is OtpVerified) {
            Navigator.pushReplacementNamed(context, '/main');
          } else if (state is RegistrationIncomplete) {
            Navigator.pushReplacementNamed(
              context,
              '/complete-registration',
              arguments: {'phone': state.phone},
            );
          } else if (state is RegisterSuccess) {
            Navigator.pushReplacementNamed(context, '/main');
          } else if (state is AuthError) {
            // Clear OTP field on error
            _otpController.clear();
            
            // Show beautiful toast for OTP errors
            final message = state.message.toLowerCase();
            if (message.contains('invalid') || 
                message.contains('expired') || 
                message.contains('otp')) {
              CustomToast.showOtpError(
                context,
                message: state.message,
                onResend: () {
                  // Resend OTP
                  if (widget.isRegistration) {
                    context.read<AuthCubit>().registerSendOtp(
                      phone: widget.phone,
                    );
                  } else {
                    context.read<AuthCubit>().sendOtp(phone: widget.phone);
                  }
                },
              );
            } else {
              CustomToast.showError(
                context,
                message: state.message,
              );
            }
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is AuthLoading,
            message: 'loading'.tr(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'verify_otp'.tr(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'otp_enter_code_message'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // OTP Input Field
                  OtpInputField(
                    controller: _otpController,
                    onCompleted: (otp) {
                      _verifyOtp();
                    },
                  ),

                  const SizedBox(height: 24),

                  // Verify OTP Button
                  CustomButton(
                    text: 'verify_otp',
                    onPressed: () {
                      if (_otpController.text.length == 6) {
                        _verifyOtp();
                      }
                    },
                    icon: const Icon(Icons.verified, size: 20),
                  ),

                  const SizedBox(height: 16),

                  // Resend OTP Button
                  TextButton(
                    onPressed: () {
                      if (widget.isRegistration) {
                        // Resend registration OTP
                        context.read<AuthCubit>().registerSendOtp(
                          phone: widget.phone,
                        );
                      } else {
                        // Resend login OTP
                        context.read<AuthCubit>().sendOtp(phone: widget.phone);
                      }
                    },
                    child: Text('resend_otp'.tr()),
                  ),

                  const SizedBox(height: 16),

                  // Back Button
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('back'.tr()),
                  ),

                  const SizedBox(height: 32),

                  // Help Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'otp_help_message'.tr(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _verifyOtp() {

    if (widget.isRegistration) {
      context.read<AuthCubit>().registerVerifyOtp(
        phone: widget.phone,
        otp: _otpController.text,
      );
    } else {
      context.read<AuthCubit>().verifyOtp(
        phone: widget.phone,
        otp: _otpController.text,
      );
    }
  }
}
