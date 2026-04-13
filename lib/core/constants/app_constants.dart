class AppConstants {
  // App Info
  static const String appName = 'User App';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String languageKey = 'language';
  
  // Default Values
  static const String defaultLanguage = 'ar';
  static const String fallbackLanguage = 'en';
  
  // Token Expiry
  static const int accessTokenExpiryHours = 4;
  static const int refreshTokenExpiryDays = 7;
  
  // OTP
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 5;
  static const int maxOtpAttempts = 3;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  
  // UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 2.0;
}

