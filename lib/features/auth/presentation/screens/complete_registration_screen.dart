import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart'
    as easy_localization;
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class CompleteRegistrationScreen extends StatefulWidget {
  const CompleteRegistrationScreen({super.key});

  @override
  State<CompleteRegistrationScreen> createState() =>
      _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState
    extends State<CompleteRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _getPhone() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['phone'] != null) {
      return args['phone'] as String;
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = _getPhone();

    if (phone == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(easy_localization.tr('phone_not_provided')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(easy_localization.tr('back')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (!mounted) return;
            if (state is RegisterSuccess) {
              // بعد إتمام التسجيل احضر البروفايل مباشرةً ليكون متاحاً في تبويب البروفايل
              context.read<AuthCubit>().getProfile();
              Navigator.pushReplacementNamed(context, '/main');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            final bool isLoading = state is AuthLoading;

            return Column(
              children: [
                // Gradient header with white logo
                Expanded(
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
                          const SizedBox(height: 12),
                          Text(
                            easy_localization.tr(
                              'complete_registration_tagline_top',
                            ),
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

                // Bottom card with form
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
                                  'complete_registration_welcome_subtitle',
                                ),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: Color(0xFF9AA0A6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                easy_localization.tr(
                                  'complete_registration_enter_personal_data',
                                ),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  color: Color(0xFF8D8D8D),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Name field
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: easy_localization.tr(
                                    'complete_registration_name_hint',
                                  ),
                                  prefixIcon: const Icon(Icons.person_outline),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE6003A),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return easy_localization.tr(
                                      'complete_registration_name_required',
                                    );
                                  }
                                  if (value.trim().length < 2) {
                                    return easy_localization.tr(
                                      'complete_registration_name_too_short',
                                    );
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: easy_localization.tr(
                                    'complete_registration_password_hint',
                                  ),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE6003A),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return easy_localization.tr(
                                      'complete_registration_password_required',
                                    );
                                  }
                                  if (value.length < 6) {
                                    return easy_localization.tr(
                                      'complete_registration_password_too_short',
                                    );
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Confirm password field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: easy_localization.tr(
                                    'complete_registration_confirm_password_hint',
                                  ),
                                  prefixIcon: const Icon(Icons.lock_reset),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FC),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE6003A),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return easy_localization.tr(
                                      'complete_registration_confirm_password_required',
                                    );
                                  }
                                  if (value != _passwordController.text) {
                                    return easy_localization.tr(
                                      'complete_registration_password_mismatch',
                                    );
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

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
                                                  context
                                                      .read<AuthCubit>()
                                                      .completeRegistration(
                                                        phone: phone,
                                                        name: _nameController.text
                                                            .trim(),
                                                        password:
                                                            _passwordController
                                                                .text,
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
                                                    'complete_registration_submit',
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w700,
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
    );
  }
}

