import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/attendance.dart';

class TeacherWorkloadSummary {
  const TeacherWorkloadSummary({
    required this.teacherName,
    required this.assignedCoverCount,
  });

  final String teacherName;
  final int assignedCoverCount;
}

class ReportsData {
  const ReportsData({
    required this.totalTeachers,
    required this.presentToday,
    required this.absentToday,
    required this.onLeaveToday,
    required this.pendingToday,
    required this.attendanceRatePercent,
    required this.totalAbsences30Days,
    required this.pendingLeaveCount,
    required this.totalCoverPeriodsMonth,
    required this.workloadBreakdown,
  });

  final int totalTeachers;
  final int presentToday;
  final int absentToday;
  final int onLeaveToday;
  final int pendingToday;
  final int attendanceRatePercent;
  final int totalAbsences30Days;
  final int pendingLeaveCount;
  final int totalCoverPeriodsMonth;
  final List<TeacherWorkloadSummary> workloadBreakdown;
}

class ReportsRepository {
  ReportsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<ReportsData> getReportsData() async {
    int totalTeachers = 0;
    int presentToday = 0;
    int absentToday = 0;
    int onLeaveToday = 0;
    int pendingToday = 0;
    int attendanceRate = 95;
    int absences30 = 0;
    int pendingLeave = 0;
    int coverMonth = 0;
    final List<TeacherWorkloadSummary> workloads = [];

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final thirtyDaysAgoStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));

    try {
      // 1. Teachers count
      final teacherRows = await _client.from('teachers').select('id, profiles(full_name, is_active)');
      final validTeachers = (teacherRows as List).where((t) {
        final p = t['profiles'];
        return p is Map && p['is_active'] != false;
      }).toList();
      totalTeachers = validTeachers.length;

      // 2. Today's attendance
      final todayAtt = await _client.from('attendance').select('status').eq('attendance_date', todayStr);
      for (final r in (todayAtt as List)) {
        final st = r['status']?.toString();
        if (st == AttendanceStatus.present.name || st == AttendanceStatus.late.name) {
          presentToday++;
        } else if (st == AttendanceStatus.leave.name) {
          onLeaveToday++;
        } else if (st == AttendanceStatus.absent.name) {
          absentToday++;
        }
      }
      pendingToday = (totalTeachers - (presentToday + onLeaveToday + absentToday)).clamp(0, totalTeachers);

      // 3. Past 30 days attendance
      final pastAtt = await _client.from('attendance').select('status').gte('attendance_date', thirtyDaysAgoStr);
      int totalRecords = pastAtt.length;
      int presentRecords = 0;
      for (final r in (pastAtt as List)) {
        final st = r['status']?.toString();
        if (st == AttendanceStatus.present.name || st == AttendanceStatus.late.name) {
          presentRecords++;
        } else if (st == AttendanceStatus.absent.name) {
          absences30++;
        }
      }

      if (totalRecords > 0) {
        attendanceRate = ((presentRecords / totalRecords) * 100).round();
      }

      // 4. Pending leaves
      final pendingLeaves = await _client.from('leave_requests').select('id').eq('status', 'pending');
      pendingLeave = (pendingLeaves as List).length;

      // 5. Replacements
      final reps = await _client.from('replacement_assignments').select(
            'id, replacement_teacher:teachers!replacement_teacher_id(profiles(full_name))',
          );
      coverMonth = (reps as List).length;

      final countMap = <String, int>{};
      for (final r in reps) {
        if (r['replacement_teacher'] is Map && (r['replacement_teacher'] as Map)['profiles'] is Map) {
          final name = (r['replacement_teacher'] as Map)['profiles']['full_name']?.toString() ?? 'Teacher';
          countMap[name] = (countMap[name] ?? 0) + 1;
        }
      }

      for (final entry in countMap.entries) {
        workloads.add(TeacherWorkloadSummary(teacherName: entry.key, assignedCoverCount: entry.value));
      }
      workloads.sort((a, b) => b.assignedCoverCount.compareTo(a.assignedCoverCount));
    } catch (_) {}

    return ReportsData(
      totalTeachers: totalTeachers,
      presentToday: presentToday,
      absentToday: absentToday,
      onLeaveToday: onLeaveToday,
      pendingToday: pendingToday,
      attendanceRatePercent: attendanceRate,
      totalAbsences30Days: absences30,
      pendingLeaveCount: pendingLeave,
      totalCoverPeriodsMonth: coverMonth,
      workloadBreakdown: workloads,
    );
  }
}

