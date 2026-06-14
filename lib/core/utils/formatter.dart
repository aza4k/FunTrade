import 'package:intl/intl.dart';

class AppFormatter {
  AppFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatPnL(double pnl) {
    if (pnl > 0) {
      return '+${_currencyFormat.format(pnl)}';
    } else if (pnl < 0) {
      // SharedPreferences might give -0.0 occasionally, handle strictly
      final absoluteAmount = _currencyFormat.format(pnl.abs());
      return '-$absoluteAmount';
    } else {
      return _currencyFormat.format(0.0);
    }
  }

  static String formatPercentage(double percent) {
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(2)}%';
  }
}
