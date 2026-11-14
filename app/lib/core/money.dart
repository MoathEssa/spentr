/// Currencies offered when the user sets an hourly rate.
class CurrencyOption {
  const CurrencyOption(this.code, this.name);

  final String code;
  final String name;

  String get label => '$code · $name';
}

const supportedCurrencies = <CurrencyOption>[
  CurrencyOption('SAR', 'Saudi Riyal'),
  CurrencyOption('USD', 'US Dollar'),
  CurrencyOption('EUR', 'Euro'),
  CurrencyOption('GBP', 'British Pound'),
  CurrencyOption('AED', 'UAE Dirham'),
];

bool isSupportedCurrency(String code) =>
    supportedCurrencies.any((currency) => currency.code == code);

/// Parses the hourly-rate field. Empty, non-numeric, and non-positive values
/// are rejected. At most two decimal places are accepted.
abstract final class RateInput {
  static final _pattern = RegExp(r'^\d+(\.\d{1,2})?$');

  static String? validate(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return 'Enter your hourly rate.';
    if (text.startsWith('-')) {
      return 'Hourly rate must be greater than zero.';
    }
    if (!_pattern.hasMatch(text)) {
      return 'Enter a valid hourly rate, such as 75.00.';
    }
    final value = double.tryParse(text);
    if (value == null || !value.isFinite) {
      return 'Enter a valid hourly rate, such as 75.00.';
    }
    if (value <= 0) return 'Hourly rate must be greater than zero.';
    return null;
  }

  static double? tryParse(String? raw) {
    if (validate(raw) != null) return null;
    return double.parse(raw!.trim());
  }
}

/// One currency format for every screen: `SAR 1,234.50`.
String formatMoney(double amount, String currencyCode) {
  if (!amount.isFinite) return '$currencyCode —';
  final sign = amount < 0 ? '-' : '';
  final fixed = amount.abs().toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final whole = fixed.substring(0, dot);
  final decimals = fixed.substring(dot + 1);
  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  return '$currencyCode $sign$grouped.$decimals';
}
