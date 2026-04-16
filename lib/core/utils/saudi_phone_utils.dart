/// Saudi mobile numbers in E.164: `+966` + 9 digits (mobiles start with `5`).
/// Matches formats used by WhatsApp (`wa.me/9665…`) and typical OTP APIs (`+9665…`).
abstract final class SaudiPhoneUtils {
  static const String dialCodeDigits = '966';

  /// Strips to the 9-digit national mobile part (e.g. `501234567`).
  static String stripToNationalDigits(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    if (d.startsWith('00')) {
      d = d.substring(2);
    }
    if (d.startsWith(dialCodeDigits)) {
      d = d.substring(dialCodeDigits.length);
    } else if (d.startsWith('0')) {
      d = d.substring(1);
    }
    if (d.length > 9) {
      d = d.substring(0, 9);
    }
    return d;
  }

  /// Full international form sent to the backend (WhatsApp-friendly E.164).
  static String toE164(String raw) {
    final national = stripToNationalDigits(raw);
    if (national.isEmpty) return '';
    return '+$dialCodeDigits$national';
  }

  /// Saudi mobile: nine digits after country code, starting with `5`.
  static bool isValidSaudiMobile(String e164) {
    return RegExp(r'^\+9665\d{8}$').hasMatch(e164);
  }
}
