import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart'
    as easy_localization;
import '../../../../core/routes/app_route_generator.dart';
import '../../../../core/utils/saudi_phone_utils.dart';
import '../widgets/saudi_phone_text_form_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class KineticForgotPasswordScreen extends StatefulWidget {
  const KineticForgotPasswordScreen({super.key});

  @override
  State<KineticForgotPasswordScreen> createState() =>
      _KineticForgotPasswordScreenState();
}

class _KineticForgotPasswordScreenState extends State<KineticForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _localPhoneController = TextEditingController();

  @override
  void dispose() {
    _localPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is ForgotPasswordOtpSent) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                Navigator.pushNamed(
                  context,
                  AppRoutes.forgotPasswordOtpKinetic,
                  arguments: <String, dynamic>{'phone': state.phone},
                );
              });
            } else if (state is AuthError) {
              if (!context.mounted) return;
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
                      minHeight: MediaQuery.sizeOf(context).height * 0.32,
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
                    offset: const Offset(0, -36),
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
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        28,
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
                                'forgot_password_screen_title',
                              ),
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                color: Color(0xFF2B2B2B),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              easy_localization.tr(
                                'forgot_password_screen_subtitle',
                              ),
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                color: Color(0xFF9AA0A6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SaudiPhoneTextFormField(
                              controller: _localPhoneController,
                              hintText: easy_localization.tr('saudi_mobile_hint'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return easy_localization.tr(
                                    'kinetic_mobile_number_required',
                                  );
                                }
                                final e164 = SaudiPhoneUtils.toE164(value);
                                if (!SaudiPhoneUtils.isValidSaudiMobile(e164)) {
                                  return easy_localization.tr(
                                    'saudi_mobile_invalid',
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
                                      onTap: isLoading
                                          ? null
                                          : () {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                final String phone =
                                                    SaudiPhoneUtils.toE164(
                                                  _localPhoneController.text,
                                                );
                                                context
                                                    .read<AuthCubit>()
                                                    .forgotPasswordSendOtp(
                                                      phone: phone,
                                                      language: lang,
                                                    );
                                              }
                                            },
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
                                                  'forgot_password_send_otp',
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
