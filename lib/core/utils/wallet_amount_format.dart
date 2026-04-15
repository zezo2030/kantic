/// Formats wallet amounts: values with absolute value ≥ 1000 use a `k` suffix (thousands).
String _formatThousandsCore(double absAmount, String currency) {
  if (absAmount < 1000) {
    return '${absAmount.toStringAsFixed(2)} $currency';
  }
  final k = absAmount / 1000;
  var body = k.toStringAsFixed(2);
  body = body.replaceFirst(RegExp(r'\.?0+$'), '');
  return '${body}k $currency';
}

/// Signed amount (balance): negatives keep a leading `-`.
String formatWalletMoney(double amount, String currency) {
  final sign = amount.isNegative ? '-' : '';
  return sign + _formatThousandsCore(amount.abs(), currency);
}

/// [absAmount] must be ≥ 0. [leadingSign] is `'+'`, `'-'`, etc.
String formatWalletMoneyWithSign(
  double absAmount,
  String currency,
  String leadingSign,
) {
  return '$leadingSign${_formatThousandsCore(absAmount.abs(), currency)}';
}
