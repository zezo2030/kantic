import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart'
    as easy_localization;
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class KineticOtpLoginScreen extends StatefulWidget {
  const KineticOtpLoginScreen({super.key});

  @override
  State<KineticOtpLoginScreen> createState() => _KineticOtpLoginScreenState();
}

class _KineticOtpLoginScreenState extends State<KineticOtpLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _localPhoneController = TextEditingController();

  @override
  void dispose() {
    _localPhoneController.dispose();
    super.dispose();
  }

  String _normalizeToInternational(String raw) {
    String value = raw.trim();
    // Support numbers entered as 00XXXXXXXX by converting to +XXXXXXXX
    if (value.startsWith('00')) {
      value = '+${value.substring(2)}';
    }
    // Keep only digits and an optional leading plus
    value = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (!value.startsWith('+')) {
      value = '+$value';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final bool isLoading = state is AuthLoading;

            return Column(
              children: [
                // Header gradient with white logo - takes remaining space
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          Color(0xFFE6003A), // deep red
                          Color(0xFFFF2871), // pink
                        ],
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
                            // Tint PNG to white to match header
                            color: Colors.white,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            easy_localization.tr('kinetic_world_of_fun'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Card body at bottom - extends to bottom of screen
                Expanded(
                  child: Transform.translate(
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 32,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/imgs/kinetic.png',
                                    height: 72,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                easy_localization.tr(
                                  'kinetic_welcome_to_kinetic',
                                ),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: Color(0xFF2B2B2B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                easy_localization.tr('login'),
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  color: Color(0xFF8D8D8D),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                easy_localization.tr(
                                  'complete_registration_welcome_subtitle',
                                ),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: Color(0xFF9AA0A6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Phone input (international format with country code)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _localPhoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        hintText: '+201001234567',
                                        filled: true,
                                        fillColor: const Color(0xFFF8F9FC),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE6003A),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return easy_localization.tr(
                                            'please_enter_phone_with_country_code',
                                          );
                                        }
                                        final normalized =
                                            _normalizeToInternational(value);
                                        final e164Like = RegExp(
                                          r'^\+[1-9]\d{7,14}$',
                                        );
                                        if (!e164Like.hasMatch(normalized)) {
                                          return easy_localization.tr(
                                            'enter_valid_international_phone',
                                          );
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Submit button (gradient)
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
                                            Color(0xFFFF5CAB), // pink
                                            Color(0xFFFF6A00), // orange
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
                                                  final String
                                                  phone = _normalizeToInternational(
                                                    _localPhoneController.text,
                                                  );
                                                  context
                                                      .read<AuthCubit>()
                                                      .sendOtp(phone: phone);
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
