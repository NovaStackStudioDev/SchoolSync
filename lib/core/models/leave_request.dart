import 'package:intl/intl.dart';

enum LeaveStatus { pending, approved, rejected }

extension LeaveStatusX on LeaveStatus {
  static LeaveStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      default:
        return LeaveStatus.pending;
    }
  }
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    this.rejectionReason,
  });

  final String id;
  final String teacherId;
  final String teacherName;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final LeaveStatus status;
  final String? rejectionReason;

  int get dayCount {
    final diff = toDate.difference(fromDate).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  factory LeaveRequest.fromMap(
    Map<String, dynamic> map, {
    String? fallbackTeacherName,
  }) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    String teacherName = fallbackTeacherName ?? 'Teacher';
    if (map['teachers'] is Map && (map['teachers'] as Map)['profiles'] is Map) {
      final prof = (map['teachers'] as Map)['profiles'] as Map;
      teacherName = prof['full_name']?.toString() ?? teacherName;
    }

    return LeaveRequest(
      id: map['id']?.toString() ?? '',
      teacherId: map['teacher_id']?.toString() ?? '',
      teacherName: teacherName,
      fromDate: parseDate(map['start_date'] ?? map['from_date']),
      toDate: parseDate(map['end_date'] ?? map['to_date']),
      reason: map['reason']?.toString() ?? 'Leave',
      status: LeaveStatusX.fromString(map['status']?.toString()),
      rejectionReason: map['rejection_reason']?.toString(),
    );
  }

  Map<String, dynamic> toMap({String? schoolId}) {
    return {
      if (schoolId != null) 'school_id': schoolId,
      'teacher_id': teacherId,
      'start_date': DateFormat('yyyy-MM-dd').format(fromDate),
      'end_date': DateFormat('yyyy-MM-dd').format(toDate),
      'reason': reason,
      'status': status.name,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    };
  }
}
