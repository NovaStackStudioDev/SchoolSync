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
}

class TimetableSlot {
  const TimetableSlot({
    required this.id,
    required this.weekday,
    required this.period,
    required this.className,
    required this.subject,
    required this.teacherName,
    this.isCover = false,
  });

  final String id;
  final String weekday;
  final SchoolPeriod period;
  final String className;
  final String subject;
  final String teacherName;
  final bool isCover;
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
}

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.isWorkingDay,
    this.label,
  });

  final DateTime date;
  final bool isWorkingDay;
  final String? label;
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
}
