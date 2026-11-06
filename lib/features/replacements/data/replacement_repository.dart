import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/attendance.dart';
import '../../../core/models/teacher.dart';
import '../../../core/models/timetable.dart';
import '../../teachers/data/teacher_repository.dart';

class ReplacementCandidate {
  const ReplacementCandidate({
    required this.teacher,
    required this.score,
    required this.reason,
    required this.isFree,
    required this.isPresent,
    required this.teachesSubject,
  });

  final Teacher teacher;
  final int score;
  final String reason;
  final bool isFree;
  final bool isPresent;
  final bool teachesSubject;
}

class ReplacementRepository {
  ReplacementRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetch all replacements for a given date.
  Future<List<ReplacementAssignment>> getReplacementsForDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final rows = await _client.from('replacement_assignments').select(
            'id, absent_teacher_id, replacement_teacher_id, assignment_date, status, timetable_id, '
            'absent_teacher:teachers!absent_teacher_id(profiles(full_name)), '
            'replacement_teacher:teachers!replacement_teacher_id(profiles(full_name)), '
            'timetables(weekday, school_classes(name), subjects(name), periods(period_number))',
          ).eq('assignment_date', dateStr);

      return (rows as List).map((r) => ReplacementAssignment.fromMap(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch cover assignments for the current teacher.
  Future<List<ReplacementAssignment>> getMyReplacements(String teacherId, {DateTime? date}) async {
    try {
      var query = _client.from('replacement_assignments').select(
            'id, absent_teacher_id, replacement_teacher_id, assignment_date, status, timetable_id, '
            'absent_teacher:teachers!absent_teacher_id(profiles(full_name)), '
            'replacement_teacher:teachers!replacement_teacher_id(profiles(full_name)), '
            'timetables(weekday, school_classes(name), subjects(name), periods(period_number))',
          ).eq('replacement_teacher_id', teacherId);

      if (date != null) {
        query = query.eq('assignment_date', DateFormat('yyyy-MM-dd').format(date));
      }

      final rows = await query.order('assignment_date', ascending: false);
      return (rows as List).map((r) => ReplacementAssignment.fromMap(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  /// Automatic candidate ranking engine for replacement:
  /// Evaluates available teachers by:
  /// 1. Presence on given date (+30)
  /// 2. Free period in timetable (+40)
  /// 3. Subject suitability (+20)
  /// 4. Workload balance (+10)
  Future<List<ReplacementCandidate>> rankCandidates({
    required DateTime date,
    required String periodId,
    required String subjectName,
    required String absentTeacherId,
    required String weekday,
  }) async {
    final teachers = await TeacherRepository().listTeachers();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Fetch attendance for the day
    final attendanceRows = await _client
        .from('attendance')
        .select('teacher_id, status')
        .eq('attendance_date', dateStr);

    final presentTeacherIds = <String>{};
    for (final r in (attendanceRows as List)) {
      final map = Map<String, dynamic>.from(r as Map);
      if (map['status'] == AttendanceStatus.present.name ||
          map['status'] == AttendanceStatus.late.name) {
        presentTeacherIds.add(map['teacher_id'].toString());
      }
    }

    // Fetch timetable for that period and weekday
    final busyRows = await _client
        .from('timetables')
        .select('teacher_id')
        .eq('weekday', weekday)
        .eq('period_id', periodId);

    final busyTeacherIds = (busyRows as List).map((r) => r['teacher_id'].toString()).toSet();

    // Fetch already assigned covers today
    final coverRows = await _client
        .from('replacement_assignments')
        .select('replacement_teacher_id')
        .eq('assignment_date', dateStr);

    final coverCounts = <String, int>{};
    for (final r in (coverRows as List)) {
      final tid = r['replacement_teacher_id']?.toString() ?? '';
      coverCounts[tid] = (coverCounts[tid] ?? 0) + 1;
    }

    final candidates = <ReplacementCandidate>[];

    for (final t in teachers) {
      if (t.id == absentTeacherId || !t.isActive) continue;

      final isFree = !busyTeacherIds.contains(t.id);
      final isPresent = presentTeacherIds.contains(t.id);
      final teachesSubject = t.subjects.any((s) => s.toLowerCase() == subjectName.toLowerCase());
      final currentCovers = coverCounts[t.id] ?? 0;

      int score = 0;
      final reasons = <String>[];

      if (isFree) {
        score += 45;
        reasons.add('Free period');
      } else {
        score -= 40;
        reasons.add('Has class');
      }

      if (isPresent) {
        score += 30;
        reasons.add('Present today');
      }

      if (teachesSubject) {
        score += 25;
        reasons.add('Teaches $subjectName');
      }

      if (currentCovers == 0) {
        score += 10;
        reasons.add('No cover yet today');
      }

      final reasonStr = reasons.join(' · ');
      candidates.add(ReplacementCandidate(
        teacher: t,
        score: score.clamp(10, 99),
        reason: reasonStr,
        isFree: isFree,
        isPresent: isPresent,
        teachesSubject: teachesSubject,
      ));
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates;
  }

  /// Assign a replacement teacher.
  Future<void> assignReplacement({
    required String absentTeacherId,
    required String replacementTeacherId,
    required String timetableId,
    required DateTime date,
    String? schoolId,
    String? actorId,
  }) async {
    final sid = schoolId ?? await _resolveSchoolId();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    await _client.from('replacement_assignments').insert({
      'absent_teacher_id': absentTeacherId,
      'replacement_teacher_id': replacementTeacherId,
      'timetable_id': timetableId,
      'assignment_date': dateStr,
      'status': 'assigned',
      if (sid != null) 'school_id': sid,
    });

    // Notify replacement teacher
    try {
      await _client.from('notifications').insert({
        'title': 'New Cover Period Assigned',
        'message': 'You have been assigned as a period cover for $dateStr.',
        'is_read': false,
      });
    } catch (_) {}

    // Audit log
    try {
      if (sid != null && actorId != null) {
        await _client.from('audit_logs').insert({
          'school_id': sid,
          'actor_id': actorId,
          'action': 'replacement_assigned',
          'details': 'Cover teacher $replacementTeacherId assigned to cover absent teacher $absentTeacherId on $dateStr.',
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

