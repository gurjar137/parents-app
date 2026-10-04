import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatINR(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
