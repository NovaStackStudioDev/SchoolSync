class School {
  const School({
    required this.id,
    required this.name,
    this.nameSi,
    this.timezone = 'Asia/Colombo',
  });

  final String id;
  final String name;
  final String? nameSi;
  final String timezone;
}

class Subject {
  const Subject({
    required this.id,
    required this.name,
    this.code,
  });

  final String id;
  final String name;
  final String? code;
}

class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.name,
    this.grade,
  });

  final String id;
  final String name;
  final String? grade;
}

class TeacherSubject {
  const TeacherSubject({
    required this.teacherId,
    required this.subjectId,
  });

  final String teacherId;
  final String subjectId;
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.actorId,
    required this.action,
    required this.createdAt,
    this.details,
  });

  final String id;
  final String actorId;
  final String action;
  final DateTime createdAt;
  final String? details;
}
