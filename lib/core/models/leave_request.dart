enum LeaveStatus { pending, approved, rejected }

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

  int get dayCount => toDate.difference(fromDate).inDays + 1;
}
