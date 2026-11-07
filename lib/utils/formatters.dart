import 'package:intl/intl.dart';
import '../services/settings_service.dart';

class Formatters {
  /// Format double amount into selected currency format e.g. "2,500 د.ج"
  /// If hideBalance is active, returns "••••"
  static String formatAmount(double amount, {bool forceShow = false}) {
    if (!forceShow && SettingsService.hideBalanceNotifier.value) {
      return '•••••• ${SettingsService.currencyNotifier.value}';
    }
    final formatter = NumberFormat('#,##0.##', 'ar');
    final formatted = formatter.format(amount);
    return '$formatted ${SettingsService.currencyNotifier.value}';
  }

  /// Format date into readable Arabic format e.g. "5 أكتوبر 2026" or relative text
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(compDate).inDays;

    if (difference == 0) {
      return 'اليوم';
    } else if (difference == 1) {
      return 'أمس';
    } else if (difference == 2) {
      return 'منذ يومين';
    } else if (difference > 2 && difference <= 10) {
      return 'منذ $difference أيام';
    } else {
      final formatter = DateFormat('d MMMM yyyy', 'ar');
      return formatter.format(date);
    }
  }

  /// Format time into Arabic format e.g. "08:30 م" or "10:15 ص"
  static String formatTime(DateTime date) {
    final formatter = DateFormat('hh:mm a', 'ar');
    return formatter.format(date);
  }

  /// Format combined date and time e.g. "اليوم 08:30 م"
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} • ${formatTime(date)}';
  }

  /// Exact date string for input fields or details
  static String formatExactDate(DateTime date) {
    final formatter = DateFormat('yyyy/MM/dd', 'ar');
    return formatter.format(date);
  }

  /// Exact time string for input fields or details
  static String formatExactTime(DateTime date) {
    final formatter = DateFormat('hh:mm a', 'ar');
    return formatter.format(date);
  }

  /// Exact date and time e.g. "2026/10/05 08:30 م"
  static String formatExactDateTime(DateTime date) {
    return '${formatExactDate(date)} ${formatExactTime(date)}';
  }

  /// Format day for navigation bar e.g. "اليوم (السبت، 7 نوفمبر)" or "الخميس، 5 نوفمبر 2026"
  static String formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(compDate).inDays;

    final dayMonthFormat = DateFormat('EEEE، d MMMM', 'ar');
    final formatted = dayMonthFormat.format(date);

    if (diff == 0) {
      return 'اليوم ($formatted)';
    } else if (diff == 1) {
      return 'أمس ($formatted)';
    } else if (diff == -1) {
      return 'غداً ($formatted)';
    } else if (date.year == now.year) {
      return formatted;
    } else {
      final fullFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');
      return fullFormat.format(date);
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
