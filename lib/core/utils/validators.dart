class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'email_required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'email_invalid';
    }
    
    return null;
  }
  
  // Phone validation (supports international format)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'phone_required';
    }
    
    // Remove all non-digit characters except +
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it starts with + and has at least 10 digits
    if (!cleaned.startsWith('+') || cleaned.length < 11) {
      return 'phone_invalid';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required';
    }
    
    if (value.length < 6) {
      return 'password_too_short';
    }
    
    if (value.length > 50) {
      return 'password_too_long';
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'confirm_password_required';
    }
    
    if (value != password) {
      return 'passwords_not_match';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'name_required';
    }
    
    if (value.length < 2) {
      return 'name_too_short';
    }
    
    if (value.length > 50) {
      return 'name_too_long';
    }
    
    return null;
  }
  
  // OTP validation
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'otp_required';
    }
    
    if (value.length != 6) {
      return 'otp_invalid_length';
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'otp_invalid_format';
    }
    
    return null;
  }
  
  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '${fieldName}_required';
    }
    return null;
  }
}

