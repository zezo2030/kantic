import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart'
    as easy_localization;
import '../../../../core/routes/app_route_generator.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// After OTP step: set new password (server verifies OTP here).
class KineticForgotPasswordNewPasswordScreen extends StatefulWidget {
  final String phone;
  final String otp;

  const KineticForgotPasswordNewPasswordScreen({
    super.key,
    required this.phone,
    required this.otp,
  });

  @override
  State<KineticForgotPasswordNewPasswordScreen> createState() =>
      _KineticForgotPasswordNewPasswordScreenState();
}

class _KineticForgotPasswordNewPasswordScreenState
    extends State<KineticForgotPasswordNewPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _awaitingResetResponse = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _awaitingResetResponse = true);
    context.read<AuthCubit>().forgotPasswordReset(
          phone: widget.phone,
          otp: widget.otp,
          newPassword: _passwordController.text,
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
              _awaitingResetResponse &&
              (current is ForgotPasswordResetSuccess || current is AuthError),
          listener: (context, state) {
            if (!context.mounted) return;
            if (state is ForgotPasswordResetSuccess) {
              if (mounted) {
                setState(() => _awaitingResetResponse = false);
              }
              final String text = state.message.isNotEmpty
                  ? state.message
                  : easy_localization.tr('success');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(text)),
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              });
            } else if (state is AuthError) {
              if (mounted) {
                setState(() => _awaitingResetResponse = false);
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              easy_localization.tr(
                                'forgot_password_new_password_title',
                              ),
                              style: const TextStyle(
                                color: Color(0xFF2B2B2B),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              easy_localization.tr(
                                'forgot_password_new_password_subtitle',
                              ),
                              style: const TextStyle(
                                color: Color(0xFF9AA0A6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: easy_localization.tr(
                                  'forgot_password_new_password',
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FC),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return easy_localization.tr(
                                    'complete_registration_password_required',
                                  );
                                }
                                if (v.length < 8) {
                                  return easy_localization.tr(
                                    'password_min_eight_chars',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: easy_localization.tr(
                                  'confirm_password',
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FC),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return easy_localization.tr(
                                    'passwords_do_not_match',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
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
                                      onTap: isLoading ? null : _submit,
                                      child: Center(
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                easy_localization.tr(
                                                  'forgot_password_reset_submit',
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
