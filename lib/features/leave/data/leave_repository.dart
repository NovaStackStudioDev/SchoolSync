import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/attendance.dart';
import '../../../core/models/leave_request.dart';

class LeaveRepository {
  LeaveRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> submitLeaveRequest({
    required String teacherId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? schoolId,
  }) async {
    final sid = schoolId ?? await _resolveSchoolId();

    final data = {
      'teacher_id': teacherId,
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      'reason': reason.trim(),
      'status': 'pending',
      if (sid != null) 'school_id': sid,
    };

    await _client.from('leave_requests').insert(data);

    // Create notification for Admin
    try {
      await _client.from('notifications').insert({
        'title': 'New Leave Request',
        'message': 'A teacher submitted a leave request for ${DateFormat('d MMM').format(startDate)} – ${DateFormat('d MMM').format(endDate)}.',
        'is_read': false,
      });
    } catch (_) {}
  }

  Future<List<LeaveRequest>> getMyLeaves(String teacherId) async {
    try {
      final rows = await _client
          .from('leave_requests')
          .select('id, teacher_id, start_date, end_date, reason, status, rejection_reason, created_at, teachers(profiles(full_name))')
          .eq('teacher_id', teacherId)
          .order('start_date', ascending: false);

      return (rows as List).map((r) => LeaveRequest.fromMap(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<LeaveRequest>> getAllLeaves({String? schoolId}) async {
    try {
      final rows = await _client
          .from('leave_requests')
          .select('id, teacher_id, start_date, end_date, reason, status, rejection_reason, created_at, teachers(profiles(full_name))')
          .order('created_at', ascending: false);

      return (rows as List).map((r) => LeaveRequest.fromMap(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> reviewLeave({
    required LeaveRequest request,
    required bool approve,
    String? rejectionReason,
    required String reviewerId,
    String? schoolId,
  }) async {
    final sid = schoolId ?? await _resolveSchoolId();
    final status = approve ? 'approved' : 'rejected';

    await _client.from('leave_requests').update({
      'status': status,
      'reviewed_by': reviewerId,
      'reviewed_at': DateTime.now().toIso8601String(),
      if (!approve && rejectionReason != null) 'rejection_reason': rejectionReason,
    }).eq('id', request.id);

    // If approved, mark attendance as leave for each day in range
    if (approve) {
      DateTime cur = request.fromDate;
      while (!cur.isAfter(request.toDate)) {
        final dStr = DateFormat('yyyy-MM-dd').format(cur);
        try {
          await _client.from('attendance').upsert({
            'teacher_id': request.teacherId,
            'attendance_date': dStr,
            'status': AttendanceStatus.leave.name,
            'note': 'Approved leave: ${request.reason}',
            if (sid != null) 'school_id': sid,
            'marked_at': DateTime.now().toIso8601String(),
          }, onConflict: 'teacher_id,attendance_date');
        } catch (_) {}
        cur = cur.add(const Duration(days: 1));
      }
    }

    // Send notification
    try {
      await _client.from('notifications').insert({
        'title': approve ? 'Leave Approved' : 'Leave Rejected',
        'message': approve
            ? 'Your leave for ${DateFormat('d MMM').format(request.fromDate)} – ${DateFormat('d MMM').format(request.toDate)} was approved.'
            : 'Your leave request was rejected: ${rejectionReason ?? "No reason specified."}',
        'is_read': false,
      });
    } catch (_) {}

    // Audit log
    try {
      if (sid != null) {
        await _client.from('audit_logs').insert({
          'school_id': sid,
          'actor_id': reviewerId,
          'action': approve ? 'leave_approved' : 'leave_rejected',
          'details': 'Leave request ${request.id} for teacher ${request.teacherName} was $status.',
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

