import 'package:intl/intl.dart';

enum AttendanceStatus { present, absent, late, leave, pending }

extension AttendanceStatusX on AttendanceStatus {
  String get nameString => name;

  static AttendanceStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'leave':
        return AttendanceStatus.leave;
      default:
        return AttendanceStatus.pending;
    }
  }
}

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

  factory AttendanceRecord.fromMap(
    Map<String, dynamic> map, {
    String? fallbackTeacherName,
  }) {
    DateTime parsedDate;
    final rawDate = map['attendance_date'] ?? map['date'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? markedAtTime;
    if (map['marked_at'] != null) {
      markedAtTime = DateTime.tryParse(map['marked_at'].toString());
    }

    String teacherName = fallbackTeacherName ?? 'Teacher';
    if (map['teachers'] is Map && (map['teachers'] as Map)['profiles'] is Map) {
      final prof = (map['teachers'] as Map)['profiles'] as Map;
      teacherName = prof['full_name']?.toString() ?? teacherName;
    } else if (map['full_name'] != null) {
      teacherName = map['full_name'].toString();
    }

    return AttendanceRecord(
      id: map['id']?.toString() ?? '',
      teacherId: map['teacher_id']?.toString() ?? '',
      teacherName: teacherName,
      date: parsedDate,
      status: AttendanceStatusX.fromString(map['status']?.toString()),
      markedAt: markedAtTime,
      note: map['note']?.toString(),
    );
  }

  Map<String, dynamic> toMap({String? schoolId}) {
    return {
      if (schoolId != null) 'school_id': schoolId,
      'teacher_id': teacherId,
      'attendance_date': DateFormat('yyyy-MM-dd').format(date),
      'status': status.name,
      'marked_at': (markedAt ?? DateTime.now()).toIso8601String(),
      if (note != null) 'note': note,
    };
  }
}
