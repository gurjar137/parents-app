import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShort(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  static String formatDayMonth(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  static String formatFull(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }
}
