import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/timetable.dart';

class CalendarRepository {
  CalendarRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetch calendar days for a 14 or 30 day window starting from startDate.
  Future<List<CalendarDay>> getDays({DateTime? startDate, int daysCount = 21}) async {
    final start = startDate ?? DateTime.now();
    final days = <CalendarDay>[];

    // Query overrides from school_calendar
    final Map<String, Map<String, dynamic>> overrides = {};
    try {
      final rows = await _client.from('school_calendar').select('id, calendar_date, is_working_day, description');
      for (final r in (rows as List)) {
        final map = Map<String, dynamic>.from(r as Map);
        if (map['calendar_date'] != null) {
          overrides[map['calendar_date'].toString()] = map;
        }
      }
    } catch (_) {}

    for (int i = 0; i < daysCount; i++) {
      final day = start.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(day);

      if (overrides.containsKey(dateKey)) {
        final ov = overrides[dateKey]!;
        final isWork = ov['is_working_day'] == true;
        days.add(CalendarDay(
          date: day,
          isWorkingDay: isWork,
          label: isWork ? 'Working Day (Configured)' : 'School Holiday',
          description: ov['description']?.toString(),
        ));
      } else {
        final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
        final isPoya = (day.day == 15 || day.day == 14); // Poya approximation
        final isWorking = !isWeekend && !isPoya;

        String? label;
        if (isWorking) {
          label = 'Working Day';
        } else if (isPoya) {
          label = 'Full Moon Poya Day';
        } else {
          label = 'Weekend';
        }

        days.add(CalendarDay(
          date: day,
          isWorkingDay: isWorking,
          label: label,
        ));
      }
    }

    return days;
  }

  /// Toggle or set a specific day as working or holiday.
  Future<void> setDayStatus({
    required DateTime date,
    required bool isWorkingDay,
    String? description,
    String? actorId,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final schoolId = await _resolveSchoolId();

    final data = {
      'calendar_date': dateStr,
      'is_working_day': isWorkingDay,
      if (description != null && description.isNotEmpty) 'description': description,
      if (schoolId != null) 'school_id': schoolId,
    };

    await _client.from('school_calendar').upsert(data, onConflict: 'calendar_date');

    // Audit log
    try {
      if (actorId != null && schoolId != null) {
        await _client.from('audit_logs').insert({
          'school_id': schoolId,
          'actor_id': actorId,
          'action': 'calendar_override',
          'details': 'Set $dateStr as ${isWorkingDay ? "Working Day" : "Holiday"}. Description: $description',
        });
      }
    } catch (_) {}
  }

  Future<String?> _resolveSchoolId() async {
    try {
      final res = await _client.from('schools').select('id').limit(1);
      if (res.isNotEmpty) return res.first['id'] as String;
    } catch (_) {}
    return null;
  }
}

