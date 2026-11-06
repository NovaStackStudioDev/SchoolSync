import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/attendance.dart';

class AttendanceRepository {
  AttendanceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Check whether the current time is before the 07:30 cutoff.
  bool isBeforeCutoff([DateTime? checkTime]) {
    final now = checkTime ?? DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
      AppConstants.attendanceCutoffHour,
      AppConstants.attendanceCutoffMinute,
    );
    return now.isBefore(cutoff);
  }

  /// Get attendance for a teacher on a specific date (defaults to today).
  Future<AttendanceRecord?> getAttendance(String teacherId, [DateTime? targetDate]) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(targetDate ?? DateTime.now());
    try {
      final row = await _client
          .from('attendance')
          .select('id, teacher_id, attendance_date, status, marked_at, note, teachers(profiles(full_name))')
          .eq('teacher_id', teacherId)
          .eq('attendance_date', dateStr)
          .maybeSingle();

      if (row == null) return null;
      return AttendanceRecord.fromMap(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  /// Mark attendance for the current logged-in teacher.
  Future<AttendanceRecord> markSelfPresent({
    required String teacherId,
    String? schoolId,
    String? note,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final sid = schoolId ?? await _resolveSchoolId();

    final data = {
      'teacher_id': teacherId,
      'attendance_date': dateStr,
      'status': isBeforeCutoff(now) ? 'present' : 'late',
      'marked_at': now.toIso8601String(),
      if (note != null && note.isNotEmpty) 'note': note,
      if (sid != null) 'school_id': sid,
    };

    final res = await _client
        .from('attendance')
        .upsert(data, onConflict: 'teacher_id,attendance_date')
        .select()
        .single();

    return AttendanceRecord.fromMap(Map<String, dynamic>.from(res));
  }

  /// Fetch full attendance list for a date (joining with all active teachers).
  Future<List<AttendanceRecord>> listAttendanceForDate(DateTime date, {String? schoolId}) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // 1. Fetch all teachers
    final teacherRows = await _client.from('teachers').select(
          'id, employee_number, profiles(full_name, is_active)',
        );

    // 2. Fetch existing attendance for this date
    final attRows = await _client
        .from('attendance')
        .select('id, teacher_id, attendance_date, status, marked_at, note')
        .eq('attendance_date', dateStr);

    final attMap = <String, Map<String, dynamic>>{};
    for (final raw in (attRows as List)) {
      final map = Map<String, dynamic>.from(raw as Map);
      attMap[map['teacher_id'].toString()] = map;
    }

    // 3. Combine
    final records = <AttendanceRecord>[];
    final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final beforeCutoff = isBeforeCutoff();

    for (final raw in (teacherRows as List)) {
      final tMap = Map<String, dynamic>.from(raw as Map);
      final tid = tMap['id'].toString();
      final prof = tMap['profiles'] is Map ? Map<String, dynamic>.from(tMap['profiles'] as Map) : {};
      if (prof['is_active'] == false) continue;

      final teacherName = prof['full_name']?.toString() ?? 'Teacher';

      if (attMap.containsKey(tid)) {
        records.add(AttendanceRecord.fromMap(
          attMap[tid]!,
          fallbackTeacherName: teacherName,
        ));
      } else {
        // Teacher has not marked attendance
        AttendanceStatus fallbackStatus;
        if (isToday) {
          fallbackStatus = beforeCutoff ? AttendanceStatus.pending : AttendanceStatus.absent;
        } else {
          fallbackStatus = AttendanceStatus.absent;
        }

        records.add(AttendanceRecord(
          id: '',
          teacherId: tid,
          teacherName: teacherName,
          date: date,
          status: fallbackStatus,
        ));
      }
    }

    return records;
  }

  /// Principal manually updates or overrides a teacher's attendance status.
  Future<void> updateAttendanceStatus({
    required String teacherId,
    required DateTime date,
    required AttendanceStatus status,
    String? note,
    String? schoolId,
    String? actorId,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final sid = schoolId ?? await _resolveSchoolId();

    final data = {
      'teacher_id': teacherId,
      'attendance_date': dateStr,
      'status': status.name,
      'marked_at': DateTime.now().toIso8601String(),
      if (note != null && note.isNotEmpty) 'note': note,
      if (sid != null) 'school_id': sid,
    };

    await _client.from('attendance').upsert(data, onConflict: 'teacher_id,attendance_date');

    // Create Audit Log
    try {
      if (actorId != null && sid != null) {
        await _client.from('audit_logs').insert({
          'school_id': sid,
          'actor_id': actorId,
          'action': 'attendance_override',
          'details': 'Changed teacher $teacherId status to ${status.name} for $dateStr. Note: ${note ?? "None"}',
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

