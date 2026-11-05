enum AttendanceStatus { present, absent, late, leave, pending }

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.date,
    required this.status,
    this.markedAt,
    this.note,
  });

  final String id;
  final String teacherId;
  final String teacherName;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? markedAt;
  final String? note;
}
