import 'package:flutter_test/flutter_test.dart';
import 'package:schoolsync/core/models/school_weekday.dart';

void main() {
  test('all ISO database weekday numbers match English UI labels', () {
    for (var day = 1; day <= 7; day++) {
      expect(SchoolWeekday.name(day), SchoolWeekday.names[day - 1]);
      expect(SchoolWeekday.number(SchoolWeekday.names[day - 1]), day);
      expect(SchoolWeekday.name('$day'), SchoolWeekday.names[day - 1]);
    }
    expect(SchoolWeekday.name(0), 'Sunday');
    expect(SchoolWeekday.name(' sunday '), 'Sunday');
  });
  test('invalid weekday values are not invented as a valid school day', () {
    for (final value in [null, -1, 8, 'Holiday', '']) {
      expect(() => SchoolWeekday.name(value), throwsFormatException);
    }
  });
}
