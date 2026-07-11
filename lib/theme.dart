import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Steam-inspired dark palette.
class AppColors {
  static const bg = Color(0xFF1B2838);
  static const surface = Color(0xFF223349);
  static const surfaceAlt = Color(0xFF2A3F5A);
  static const accent = Color(0xFF66C0F4); // Steam blue
  static const sale = Color(0xFF4C9F38); // Steam green discount
  static const saleText = Color(0xFFBEEE11);
  static const low = Color(0xFFFFD166); // historical-low gold
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.sale,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: false,
    ),
    cardColor: AppColors.surface,
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.accent,
      thumbColor: AppColors.accent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

/// Format a price in the catalog currency (₹ for INR, $ otherwise).
String formatPrice(double? amount, String currency) {
  if (amount == null) return '—';
  if (amount == 0) return 'Free';
  if (currency == 'INR') {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(amount);
  }
  return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
}

String formatPlayers(int? n) {
  if (n == null) return '';
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
