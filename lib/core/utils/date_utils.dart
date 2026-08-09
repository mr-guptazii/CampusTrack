import 'package:intl/intl.dart';

/// Date/time formatting helpers shared across screens.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _weekday = DateFormat('EEEE');
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  static String dayMonth(DateTime d) => _dayMonth.format(d);
  static String dayMonthYear(DateTime d) => _dayMonthYear.format(d);
  static String time(DateTime d) => _time.format(d);
  static String weekday(DateTime d) => _weekday.format(d);
  static String iso(DateTime d) => _iso.format(d);

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static List<DateTime> lastNDays(int n, {DateTime? from}) {
    final base = startOfDay(from ?? DateTime.now());
    return List.generate(n, (i) => base.subtract(Duration(days: n - 1 - i)));
  }

  /// Formats a "HH:mm" 24h string (as stored in TimetableEntry) to 12h form.
  static String formatHHmm(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return _time.format(dt);
  }

  static int minutesSinceMidnight(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }
}

/// Weekday enum mapped to DateTime.weekday (1 = Monday ... 7 = Sunday).
enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

extension WeekdayX on Weekday {
  int get isoValue => index + 1;

  String get label {
    switch (this) {
      case Weekday.monday:
        return 'Monday';
      case Weekday.tuesday:
        return 'Tuesday';
      case Weekday.wednesday:
        return 'Wednesday';
      case Weekday.thursday:
        return 'Thursday';
      case Weekday.friday:
        return 'Friday';
      case Weekday.saturday:
        return 'Saturday';
      case Weekday.sunday:
        return 'Sunday';
    }
  }

  String get short => label.substring(0, 3);

  static Weekday fromDateTime(DateTime d) => Weekday.values[d.weekday - 1];

  static Weekday fromIndex(int i) => Weekday.values[i % 7];
}
