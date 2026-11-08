/// Shared boundary between legacy numeric database weekdays and UI labels.
abstract final class SchoolWeekday {
  static const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static int number(Object? value) {
    final raw = value?.toString().trim() ?? '';
    final numeric = int.tryParse(raw);
    if (numeric == 0) {
      return DateTime.sunday;
    }
    if (numeric != null &&
        numeric >= DateTime.monday &&
        numeric <= DateTime.sunday) {
      return numeric;
    }
    final index = names.indexWhere(
      (name) => name.toLowerCase() == raw.toLowerCase(),
    );
    if (index >= 0) {
      return index + 1;
    }
    throw FormatException(
      'Invalid school weekday: $value. Expected Monday–Sunday or 1–7.',
    );
  }

  static String name(Object? value) => names[number(value) - 1];
}
