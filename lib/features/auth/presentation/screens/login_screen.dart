import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatLoginError(String message) {
    // Normalize message for comparison
    final normalizedMessage = message.trim();
    final lowerMessage = normalizedMessage.toLowerCase();
    
    // First check: if message is exactly "invalid_credentials" (highest priority)
    if (lowerMessage == 'invalid_credentials' || 
        normalizedMessage == 'invalid_credentials') {
      return 'invalid_credentials'.tr();
    }
    
    // Second check: if message is exactly a translation key (case-insensitive)
    if (lowerMessage == 'wrong_password' ||
        lowerMessage == 'phone_not_found' ||
        lowerMessage == 'user_not_found' ||
        lowerMessage == 'account_inactive') {
      // Translate using the lowercase key
      return lowerMessage.tr();
    }
    
    // Second check: exact match (case-sensitive) - in case server sends exact key
    if (normalizedMessage == 'wrong_password' ||
        normalizedMessage == 'phone_not_found' ||
        normalizedMessage == 'user_not_found' ||
        normalizedMessage == 'invalid_credentials' ||
        normalizedMessage == 'account_inactive') {
      return normalizedMessage.tr();
    }
    
    // Remove technical exception details
    if (normalizedMessage.contains('DioException') ||
        normalizedMessage.contains('Exception:') ||
        normalizedMessage.contains('bad response') ||
        normalizedMessage.contains('status code') ||
        normalizedMessage.contains('RequestOptions') ||
        normalizedMessage.contains('validateStatus') ||
        normalizedMessage.contains('developer.mozilla.org') ||
        normalizedMessage.contains('Client error') ||
        normalizedMessage.contains('401')) {
      // For 401 errors, default to wrong password
      return 'wrong_password'.tr();
    }
    
    // Check for specific error patterns from server
    if (lowerMessage.contains('invalid credentials')) {
      // When server returns "Invalid credentials", show the specific message
      return 'invalid_credentials'.tr();
    } else if (lowerMessage.contains('wrong password') ||
        lowerMessage.contains('incorrect password') ||
        lowerMessage.contains('password is incorrect') ||
        lowerMessage.contains('unauthorized')) {
      return 'wrong_password'.tr();
    } else if (lowerMessage.contains('phone') &&
        (lowerMessage.contains('not found') ||
            lowerMessage.contains('does not exist') ||
            lowerMessage.contains('not registered'))) {
      return 'phone_not_found'.tr();
    } else if (lowerMessage.contains('user') &&
        (lowerMessage.contains('not found') ||
            lowerMessage.contains('does not exist'))) {
      return 'user_not_found'.tr();
    } else if (lowerMessage.contains('inactive') ||
        lowerMessage.contains('not active')) {
      return 'account_inactive'.tr();
    }
    
    // Try to translate if it looks like a translation key
    if (normalizedMessage.contains('_') && 
        !normalizedMessage.contains(' ') &&
        !normalizedMessage.contains('.')) {
      // Might be a translation key - try to translate it
      try {
        final translated = normalizedMessage.tr();
        // If translation returns different text, use it
        if (translated != normalizedMessage && translated.isNotEmpty) {
          return translated;
        }
      } catch (e) {
        // Translation failed, continue to check
      }
      
      // If it's exactly "invalid_credentials", translate it
      if (normalizedMessage.toLowerCase() == 'invalid_credentials') {
        return 'invalid_credentials'.tr();
      }
    }
    
    // Additional check: if message contains "invalid_credentials" anywhere
    if (normalizedMessage.toLowerCase().contains('invalid_credentials') ||
        normalizedMessage == 'invalid_credentials') {
      return 'invalid_credentials'.tr();
    }
    
    // Default fallback - always return translated message
    // If we got here and message contains "invalid", use invalid_credentials
    if (lowerMessage.contains('invalid')) {
      return 'invalid_credentials'.tr();
    }
    
    // Final fallback
    return 'invalid_credentials'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('login'.tr()), centerTitle: true),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.pushReplacementNamed(context, '/main');
          } else if (state is AuthError) {
            // Format error message for better UX
            String errorMessage = _formatLoginError(state.message);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is AuthLoading,
            message: 'loading'.tr(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      'welcome'.tr(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'login_subtitle'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Phone Field
                    CustomTextField(
                      label: 'phone'.tr(),
                      hint: 'phone_hint'.tr(),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'phone_required'.tr();
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    CustomTextField(
                      label: 'password'.tr(),
                      hint: 'password_hint'.tr(),
                      controller: _passwordController,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'password_required'.tr();
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    CustomButton(
                      text: 'login',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<AuthCubit>().login(
                            phone: _phoneController.text.trim(),
                            password: _passwordController.text,
                          );
                        }
                      },
                      icon: const Icon(Icons.login, size: 20),
                    ),

                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('no_account'.tr()),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: Text('register'.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
