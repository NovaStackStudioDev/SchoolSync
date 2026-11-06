class SchoolPeriod {
  const SchoolPeriod({
    required this.id,
    required this.number,
    required this.label,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final int number;
  final String label;
  final String startTime;
  final String endTime;

  factory SchoolPeriod.fromMap(Map<String, dynamic> map) {
    final num = map['period_number'] is int
        ? map['period_number'] as int
        : int.tryParse(map['period_number']?.toString() ?? '') ??
              (map['number'] is int ? map['number'] as int : 1);
    return SchoolPeriod(
      id: map['id']?.toString() ?? '',
      number: num,
      label: map['label']?.toString() ?? 'Period $num',
      startTime: map['start_time']?.toString() ?? '08:00',
      endTime: map['end_time']?.toString() ?? '08:40',
    );
  }

  Map<String, dynamic> toMap({String? schoolId}) {
    return {
      'school_id': ?schoolId,
      'period_number': number,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}

class TimetableSlot {
  const TimetableSlot({
    required this.id,
    required this.weekday,
    required this.period,
    required this.className,
    required this.subject,
    required this.teacherName,
    this.teacherId = '',
    this.classId = '',
    this.subjectId = '',
    this.isCover = false,
  });

  final String id;
  final String weekday;
  final SchoolPeriod period;
  final String className;
  final String subject;
  final String teacherName;
  final String teacherId;
  final String classId;
  final String subjectId;
  final bool isCover;

  factory TimetableSlot.fromMap(
    Map<String, dynamic> map, {
    SchoolPeriod? period,
    bool isCover = false,
  }) {
    String teacherName = 'Teacher';
    if (map['teachers'] is Map && (map['teachers'] as Map)['profiles'] is Map) {
      final prof = (map['teachers'] as Map)['profiles'] as Map;
      teacherName = prof['full_name']?.toString() ?? teacherName;
    }

    String className = 'Class';
    if (map['school_classes'] is Map) {
      className =
          (map['school_classes'] as Map)['name']?.toString() ?? className;
    } else if (map['class_name'] != null) {
      className = map['class_name'].toString();
    }

    String subjectName = 'Subject';
    if (map['subjects'] is Map) {
      subjectName = (map['subjects'] as Map)['name']?.toString() ?? subjectName;
    } else if (map['subject_name'] != null) {
      subjectName = map['subject_name'].toString();
    }

    SchoolPeriod resolvedPeriod;
    if (period != null) {
      resolvedPeriod = period;
    } else if (map['periods'] is Map) {
      resolvedPeriod = SchoolPeriod.fromMap(
        Map<String, dynamic>.from(map['periods'] as Map),
      );
    } else {
      resolvedPeriod = const SchoolPeriod(
        id: '',
        number: 1,
        label: 'Period 1',
        startTime: '07:40',
        endTime: '08:20',
      );
    }

    return TimetableSlot(
      id: map['id']?.toString() ?? '',
      weekday: map['weekday']?.toString() ?? 'Monday',
      period: resolvedPeriod,
      className: className,
      subject: subjectName,
      teacherName: teacherName,
      teacherId: map['teacher_id']?.toString() ?? '',
      classId: map['class_id']?.toString() ?? '',
      subjectId: map['subject_id']?.toString() ?? '',
      isCover: isCover,
    );
  }
}

class ReplacementAssignment {
  const ReplacementAssignment({
    required this.id,
    required this.absentTeacher,
    required this.coverTeacher,
    required this.className,
    required this.subject,
    required this.periodLabel,
    required this.weekday,
    required this.status,
    this.score,
    this.absentTeacherId = '',
    this.coverTeacherId = '',
    this.timetableId = '',
    this.assignmentDate,
  });

  final String id;
  final String absentTeacher;
  final String coverTeacher;
  final String className;
  final String subject;
  final String periodLabel;
  final String weekday;
  final String status;
  final int? score;
  final String absentTeacherId;
  final String coverTeacherId;
  final String timetableId;
  final DateTime? assignmentDate;

  factory ReplacementAssignment.fromMap(Map<String, dynamic> map) {
    String absentName = 'Absent Teacher';
    if (map['absent_teacher'] is Map &&
        (map['absent_teacher'] as Map)['profiles'] is Map) {
      final p = (map['absent_teacher'] as Map)['profiles'] as Map;
      absentName = p['full_name']?.toString() ?? absentName;
    }

    String coverName = 'Cover Teacher';
    if (map['replacement_teacher'] is Map &&
        (map['replacement_teacher'] as Map)['profiles'] is Map) {
      final p = (map['replacement_teacher'] as Map)['profiles'] as Map;
      coverName = p['full_name']?.toString() ?? coverName;
    }

    String className = 'Class';
    String subjectName = 'Subject';
    String periodLabel = 'Period';
    String weekday = 'Monday';

    if (map['timetables'] is Map) {
      final tt = map['timetables'] as Map;
      weekday = tt['weekday']?.toString() ?? weekday;
      if (tt['school_classes'] is Map) {
        className =
            (tt['school_classes'] as Map)['name']?.toString() ?? className;
      }
      if (tt['subjects'] is Map) {
        subjectName =
            (tt['subjects'] as Map)['name']?.toString() ?? subjectName;
      }
      if (tt['periods'] is Map) {
        final p = tt['periods'] as Map;
        final num = p['period_number'] ?? p['number'] ?? 1;
        periodLabel = 'Period $num';
      }
    }

    DateTime? date;
    if (map['assignment_date'] != null) {
      date = DateTime.tryParse(map['assignment_date'].toString());
    }

    return ReplacementAssignment(
      id: map['id']?.toString() ?? '',
      absentTeacher: absentName,
      coverTeacher: coverName,
      className: className,
      subject: subjectName,
      periodLabel: periodLabel,
      weekday: weekday,
      status: map['status']?.toString() == 'assigned'
          ? 'Assigned'
          : 'Suggested',
      absentTeacherId: map['absent_teacher_id']?.toString() ?? '',
      coverTeacherId: map['replacement_teacher_id']?.toString() ?? '',
      timetableId: map['timetable_id']?.toString() ?? '',
      assignmentDate: date,
    );
  }
}

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.isWorkingDay,
    this.label,
    this.description,
  });

  final DateTime date;
  final bool isWorkingDay;
  final String? label;
  final String? description;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.icon = 'campaign',
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String icon;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    DateTime time = DateTime.now();
    if (map['created_at'] != null) {
      time = DateTime.tryParse(map['created_at'].toString()) ?? time;
    }
    return AppNotification(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Notification',
      body: map['message']?.toString() ?? (map['body']?.toString() ?? ''),
      createdAt: time,
      isRead: map['is_read'] == true,
      icon: map['icon']?.toString() ?? 'bell',
    );
  }
}
