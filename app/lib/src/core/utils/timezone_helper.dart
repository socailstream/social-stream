import 'package:intl/intl.dart';

/// Helper class for handling Pakistan timezone (PKT - UTC+5)
class TimezoneHelper {
  // Pakistan Standard Time is UTC+5
  static const int _pakistanOffsetHours = 5;
  static const Duration _pakistanOffset = Duration(hours: _pakistanOffsetHours);

  /// Get current time in Pakistan timezone
  static DateTime now() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(_pakistanOffset);
  }

  /// Convert a DateTime to Pakistan timezone
  static DateTime toPakistanTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return utc.add(_pakistanOffset);
  }

  /// Convert Pakistan time to UTC
  static DateTime toUtc(DateTime pakistanTime) {
    return pakistanTime.subtract(_pakistanOffset);
  }

  /// Format a DateTime in Pakistan timezone
  static String format(DateTime dateTime, String pattern) {
    final pakistanTime = toPakistanTime(dateTime);
    return DateFormat(pattern).format(pakistanTime);
  }

  /// Format with default pattern (yyyy-MM-dd HH:mm)
  static String formatDefault(DateTime dateTime) {
    return format(dateTime, 'yyyy-MM-dd HH:mm');
  }

  /// Format for display (e.g., "Dec 14, 2025 10:30 AM")
  static String formatDisplay(DateTime dateTime) {
    return format(dateTime, 'MMM dd, yyyy hh:mm a');
  }

  /// Format time only (e.g., "10:30 AM")
  static String formatTime(DateTime dateTime) {
    return format(dateTime, 'hh:mm a');
  }

  /// Format date only (e.g., "Dec 14, 2025")
  static String formatDate(DateTime dateTime) {
    return format(dateTime, 'MMM dd, yyyy');
  }

  /// Get relative time string (e.g., "2 hours ago", "Just now")
  static String getRelativeTime(DateTime dateTime) {
    final pakistanTime = toPakistanTime(dateTime);
    final currentTime = now();
    final difference = currentTime.difference(pakistanTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes min${minutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Check if date is today in Pakistan timezone
  static bool isToday(DateTime dateTime) {
    final pakistanTime = toPakistanTime(dateTime);
    final today = now();
    return pakistanTime.year == today.year &&
        pakistanTime.month == today.month &&
        pakistanTime.day == today.day;
  }

  /// Check if date is tomorrow in Pakistan timezone
  static bool isTomorrow(DateTime dateTime) {
    final pakistanTime = toPakistanTime(dateTime);
    final tomorrow = now().add(const Duration(days: 1));
    return pakistanTime.year == tomorrow.year &&
        pakistanTime.month == tomorrow.month &&
        pakistanTime.day == tomorrow.day;
  }

  /// Get start of day in Pakistan timezone
  static DateTime startOfDay([DateTime? dateTime]) {
    final date = dateTime != null ? toPakistanTime(dateTime) : now();
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day in Pakistan timezone
  static DateTime endOfDay([DateTime? dateTime]) {
    final date = dateTime != null ? toPakistanTime(dateTime) : now();
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}
