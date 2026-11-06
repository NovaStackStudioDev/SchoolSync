import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/timetable.dart';

class TimetableRepository {
  TimetableRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetch all school periods (1 to 8). Auto-seeds standard periods if empty.
  Future<List<SchoolPeriod>> getPeriods() async {
    try {
      final rows = await _client
          .from('periods')
          .select('id, period_number, start_time, end_time')
          .order('period_number', ascending: true);

      if ((rows as List).isNotEmpty) {
        return rows.map((r) => SchoolPeriod.fromMap(Map<String, dynamic>.from(r as Map))).toList();
      }
    } catch (_) {}

    // Auto-seed standard Sri Lanka school periods into database
    final schoolId = await _resolveSchoolId();
    if (schoolId != null) {
      final defaultPeriods = [
        {'school_id': schoolId, 'period_number': 1, 'start_time': '07:40', 'end_time': '08:20'},
        {'school_id': schoolId, 'period_number': 2, 'start_time': '08:20', 'end_time': '09:00'},
        {'school_id': schoolId, 'period_number': 3, 'start_time': '09:00', 'end_time': '09:40'},
        {'school_id': schoolId, 'period_number': 4, 'start_time': '10:00', 'end_time': '10:40'},
        {'school_id': schoolId, 'period_number': 5, 'start_time': '10:40', 'end_time': '11:20'},
        {'school_id': schoolId, 'period_number': 6, 'start_time': '11:20', 'end_time': '12:00'},
        {'school_id': schoolId, 'period_number': 7, 'start_time': '12:40', 'end_time': '13:20'},
        {'school_id': schoolId, 'period_number': 8, 'start_time': '13:20', 'end_time': '14:00'},
      ];

      try {
        final inserted = await _client.from('periods').insert(defaultPeriods).select();
        return (inserted as List).map((r) => SchoolPeriod.fromMap(Map<String, dynamic>.from(r as Map))).toList();
      } catch (_) {}
    }

    // Fallback in-memory periods if DB write fails
    return const [
      SchoolPeriod(id: 'p1', number: 1, label: 'Period 1', startTime: '07:40', endTime: '08:20'),
      SchoolPeriod(id: 'p2', number: 2, label: 'Period 2', startTime: '08:20', endTime: '09:00'),
      SchoolPeriod(id: 'p3', number: 3, label: 'Period 3', startTime: '09:00', endTime: '09:40'),
      SchoolPeriod(id: 'p4', number: 4, label: 'Period 4', startTime: '10:00', endTime: '10:40'),
      SchoolPeriod(id: 'p5', number: 5, label: 'Period 5', startTime: '10:40', endTime: '11:20'),
      SchoolPeriod(id: 'p6', number: 6, label: 'Period 6', startTime: '11:20', endTime: '12:00'),
      SchoolPeriod(id: 'p7', number: 7, label: 'Period 7', startTime: '12:40', endTime: '13:20'),
      SchoolPeriod(id: 'p8', number: 8, label: 'Period 8', startTime: '13:20', endTime: '14:00'),
    ];
  }

  /// Fetch school classes. Auto-seeds standard classes if empty.
  Future<List<Map<String, dynamic>>> getClasses() async {
    try {
      final rows = await _client.from('school_classes').select('id, name').order('name');
      if ((rows as List).isNotEmpty) {
        return (rows).map((r) => Map<String, dynamic>.from(r as Map)).toList();
      }
    } catch (_) {}

    final schoolId = await _resolveSchoolId();
    if (schoolId != null) {
      final defaultClasses = [
        {'school_id': schoolId, 'name': 'Grade 9-A'},
        {'school_id': schoolId, 'name': 'Grade 9-B'},
        {'school_id': schoolId, 'name': 'Grade 10-A'},
        {'school_id': schoolId, 'name': 'Grade 10-B'},
        {'school_id': schoolId, 'name': 'Grade 11-A'},
        {'school_id': schoolId, 'name': 'Grade 11-B'},
      ];
      try {
        final inserted = await _client.from('school_classes').insert(defaultClasses).select();
        return (inserted as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
      } catch (_) {}
    }

    return const [];
  }

  /// Get teacher timetable slots for a specific weekday.
  Future<List<TimetableSlot>> getTeacherTimetable(String teacherId, {String? weekday}) async {
    try {
      var query = _client.from('timetables').select(
            'id, weekday, class_id, subject_id, teacher_id, period_id, '
            'periods(id, period_number, start_time, end_time), '
            'school_classes(name), '
            'subjects(name), '
            'teachers(profiles(full_name))',
          ).eq('teacher_id', teacherId);

      if (weekday != null) {
        query = query.eq('weekday', weekday);
      }

      final rows = await query;
      return (rows as List).map((r) => TimetableSlot.fromMap(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get all timetable slots for school on a specific weekday.
  Future<List<TimetableSlot>> getAllTimetables({String? weekday}) async {
    try {
      var query = _client.from('timetables').select(
            'id, weekday, class_id, subject_id, teacher_id, period_id, '
            'periods(id, period_number, start_time, end_time), '
            'school_classes(name), '
            'subjects(name), '
            'teachers(profiles(full_name))',
          );

      if (weekday != null) {
        query = query.eq('weekday', weekday);
      }

      final rows = await query;
      return (rows as List).map((r) => TimetableSlot.fromMap(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a new timetable slot.
  Future<void> addTimetableSlot({
    required String weekday,
    required String teacherId,
    required String classId,
    required String subjectId,
    required String periodId,
    String? schoolId,
  }) async {
    final sid = schoolId ?? await _resolveSchoolId();
    await _client.from('timetables').insert({
      'weekday': weekday,
      'teacher_id': teacherId,
      'class_id': classId,
      'subject_id': subjectId,
      'period_id': periodId,
      if (sid != null) 'school_id': sid,
    });
  }

  Future<String?> _resolveSchoolId() async {
    try {
      final res = await _client.from('schools').select('id').eq('name', AppConstants.schoolName).limit(1);
      if (res.isNotEmpty) return res.first['id'] as String;
      final anyRes = await _client.from('schools').select('id').limit(1);
      if (anyRes.isNotEmpty) return anyRes.first['id'] as String;
    } catch (_) {}
    return null;
  }
}

