import 'dart:convert';
import 'package:dio/dio.dart';
import '../errors/failures.dart';

// String extensions
extension StringExtensions on String {
  // Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  // Check if string is a valid phone number
  bool get isValidPhone {
    final cleaned = replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.startsWith('+') && cleaned.length >= 11;
  }

  // Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  // Remove all whitespace
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }
}

// DioException to Failure conversion
extension DioExceptionToFailure on DioException {
  Failure toFailure() {

    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure(
          message: 'Connection timeout. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode;
        final message = _getErrorMessage(statusCode);

        if (statusCode == 401) {
          // Check for specific authentication errors
          final errorMessage = message.toLowerCase();
          if (errorMessage.contains('invalid credentials')) {
            // Server explicitly says "Invalid credentials"
            return InvalidCredentialsFailure(
              message: 'invalid_credentials',
            );
          } else if (errorMessage.contains('wrong password') ||
              errorMessage.contains('incorrect password') ||
              errorMessage.contains('password is incorrect')) {
            return InvalidCredentialsFailure(
              message: 'wrong_password',
            );
          } else if (errorMessage.contains('phone') &&
              (errorMessage.contains('not found') ||
                  errorMessage.contains('does not exist') ||
                  errorMessage.contains('not registered'))) {
            return InvalidCredentialsFailure(
              message: 'phone_not_found',
            );
          } else if (errorMessage.contains('user') &&
              (errorMessage.contains('not found') ||
                  errorMessage.contains('does not exist'))) {
            return InvalidCredentialsFailure(
              message: 'user_not_found',
            );
          } else if (errorMessage.contains('inactive') ||
              errorMessage.contains('not active')) {
            return AuthenticationFailure(
              message: 'account_inactive',
              statusCode: statusCode,
            );
          }
          return AuthenticationFailure(
            message: message.contains('invalid_credentials') || 
                     message.contains('wrong_password') ||
                     message.contains('phone_not_found') ||
                     message.contains('user_not_found')
                ? message
                : 'invalid_credentials',
            statusCode: statusCode,
          );
        } else if (statusCode == 400) {
          return ValidationFailure(message: message);
        } else {
          return ServerFailure(message: message, statusCode: statusCode);
        }

      case DioExceptionType.cancel:
        return const NetworkFailure(message: 'Request was cancelled.');

      case DioExceptionType.connectionError:
        return const NetworkFailure(
          message:
              'Unable to connect to server. Please check your internet connection.',
        );

      case DioExceptionType.unknown:
        // Often happens when the server closes the connection early, e.g.:
        // "Connection closed before full header was received"
        final details = error?.toString() ?? message;
        if (details != null &&
            details.contains('Connection closed before full header was received')) {
          return const NetworkFailure(
            message:
                'The server closed the connection unexpectedly. Please try again.',
          );
        }
        return UnknownFailure(
          message: details ?? 'An unknown error occurred.',
        );

      default:
        return UnknownFailure(message: message ?? 'An unknown error occurred.');
    }
  }

  String _getErrorMessage(int? statusCode) {

    // Try to extract message from response data
    if (response?.data != null) {
      final responseData = response!.data;
      
      // Handle Map response
      if (responseData is Map<String, dynamic>) {
        final data = responseData;
        final message = data['message'] ?? 'unknown_error';
        
        // Check if message is already a translation key (case-insensitive)
        if (message is String) {
          final lowerMsg = message.toLowerCase().trim();
          if (lowerMsg == 'wrong_password' ||
              lowerMsg == 'phone_not_found' ||
              lowerMsg == 'user_not_found' ||
              lowerMsg == 'invalid_credentials' ||
              lowerMsg == 'account_inactive') {
            // Return the normalized key for translation
            return lowerMsg;
          }
          // Also check exact match
          if (message == 'wrong_password' ||
              message == 'phone_not_found' ||
              message == 'user_not_found' ||
              message == 'invalid_credentials' ||
              message == 'account_inactive') {
            return message;
          }
        }
        
        // If message contains technical details, return translation key
        final lowerMsg = message.toString().toLowerCase();
        if (lowerMsg.contains('invalid credentials')) {
          // Server explicitly says "Invalid credentials"
          return 'invalid_credentials';
        } else if (lowerMsg.contains('unauthorized') ||
            lowerMsg.contains('wrong password') ||
            lowerMsg.contains('incorrect password')) {
          return 'wrong_password';
        } else if (lowerMsg.contains('phone') && 
                   (lowerMsg.contains('not found') || 
                    lowerMsg.contains('does not exist'))) {
          return 'phone_not_found';
        } else if (lowerMsg.contains('user') && 
                   (lowerMsg.contains('not found') || 
                    lowerMsg.contains('does not exist'))) {
          return 'user_not_found';
        }
        
        return message.toString();
      }
      
      // Handle String response (JSON string)
      if (response?.data is String) {
        try {
          final jsonData = jsonDecode(response!.data as String) as Map<String, dynamic>;
          final message = jsonData['message'] ?? 'Server error occurred.';
          return message;
        } catch (e) {
        }
      }
    }

    // Fallback to status code based messages - use translation keys
    switch (statusCode) {
      case 400:
        return 'bad_request';
      case 401:
        return 'wrong_password'; // Default to wrong password for 401
      case 403:
        return 'forbidden';
      case 404:
        return 'not_found';
      case 429:
        return 'too_many_requests';
      case 500:
        return 'internal_server_error';
      default:
        return 'unknown_error';
    }
  }
}
