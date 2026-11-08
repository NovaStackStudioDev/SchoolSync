import 'package:intl/intl.dart';

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'school_database.dart';
import '../models/school_weekday.dart';

class SchoolRepository extends SchoolDatabase {
  SchoolRepository({super.client});

  Future<List<DbRow>> teachers() => rows(
    'teachers',
    select: '*, profiles!teachers_profile_id_fkey(full_name,is_active), teacher_subjects(subjects(id,name))',
  );
  Future<List<DbRow>> classes() => rows(
    'school_classes',
    select: '*, students(id,is_active)',
    order: 'name',
  );
  Future<List<DbRow>> students(String classId) async => (await rows(
    'students',
    order: 'full_name',
  )).where((r) => r['class_id'] == classId).toList();
  Future<List<DbRow>> periods() => rows('periods', order: 'period_number');
  Future<List<DbRow>> subjects() => rows('subjects', order: 'name');

  Future<List<DbRow>> timetable({
    String? teacher,
    String? weekday,
    DateTime? date,
  }) async {
    final asOf = SchoolDatabase.date(date ?? SchoolDatabase.now);
    final requestedDay = weekday == null ? null : SchoolWeekday.number(weekday);
    var query = client
        .from('timetables')
        .select(
          '*, periods(*), school_classes(name), subjects(name), teachers(profiles!teachers_profile_id_fkey(full_name))',
        )
        .eq('school_id', await schoolId())
        .eq('is_archived', false)
        .lte('valid_from', asOf)
        .or('valid_to.is.null,valid_to.gte.$asOf');
    if (teacher != null) query = query.eq('teacher_id', teacher);
    // Some installed databases store an integer weekday, others use names.
    // Filter after the scoped, paginated read so a text filter cannot fail an
    // integer column, and normalize values before any UI/edit form sees them.
    final result = await readAll(query);
    return result
        .where(
          (row) =>
              requestedDay == null ||
              SchoolWeekday.number(row['weekday']) == requestedDay,
        )
        .map((row) => {...row, 'weekday': SchoolWeekday.name(row['weekday'])})
        .toList()
      ..sort(
        (a, b) => ((a['periods']?['period_number'] as int?) ?? 0).compareTo(
          (b['periods']?['period_number'] as int?) ?? 0,
        ),
      );
  }

  Future<void> saveTimetable(DbRow values, {String? id}) async {
    await requirePrincipal();
    await rpc('save_timetable_slot', {
      'slot': {...values, 'id': ?id},
    });
  }

  Future<List<DbRow>> teacherAttendance(DateTime date) async {
    final staff = await teachers();
    final saved = await client
        .from('attendance')
        .select()
        .eq('school_id', await schoolId())
        .eq('attendance_date', SchoolDatabase.date(date));
    final byTeacher = {
      for (final record in saved) record['teacher_id']: record,
    };
    return staff
        .where((t) => t['profiles']?['is_active'] == true)
        .map(
          (t) => <String, dynamic>{
            'teacher_id': t['id'],
            'full_name': t['profiles']?['full_name'],
            'status': byTeacher[t['id']]?['status'] ?? 'unmarked',
            'marked_at': byTeacher[t['id']]?['marked_at'],
          },
        )
        .toList();
  }

  Future<DbRow?> myAttendance() async {
    final result = await client
        .from('attendance')
        .select()
        .eq('school_id', await schoolId())
        .eq('teacher_id', await requireTeacherId())
        .eq('attendance_date', SchoolDatabase.today)
        .maybeSingle();
    return result;
  }

  Future<void> checkIn() => rpc('check_in', {});
  Future<void> setTeacherAttendance(
    String teacher,
    DateTime day,
    String status,
  ) => rpc('set_teacher_attendance', {
    'target_teacher': teacher,
    'target_date': SchoolDatabase.date(day),
    'new_status': status,
  });

  Future<List<DbRow>> studentAttendance(String classId, DateTime date) async {
    final pupils = await students(classId);
    final saved = await client
        .from('student_attendance')
        .select()
        .eq('school_id', await schoolId())
        .eq('class_id', classId)
        .eq('attendance_date', SchoolDatabase.date(date));
    final byStudent = {
      for (final record in saved) record['student_id']: record['status'],
    };
    return pupils
        .where((s) => s['is_active'] == true)
        .map((s) => {...s, 'status': byStudent[s['id']] ?? 'unmarked'})
        .toList();
  }

  Future<void> saveStudentAttendance(
    String classId,
    DateTime date,
    Map<String, String> statuses,
  ) async {
    if (statuses.isEmpty) {
      throw StateError('Mark at least one student before saving.');
    }
    await rpc('save_student_attendance', {
      'target_class': classId,
      'target_date': SchoolDatabase.date(date),
      'marks': statuses.entries
          .map((e) => {'student_id': e.key, 'status': e.value})
          .toList(),
    });
  }

  Future<List<DbRow>> leaves({bool mine = false}) async {
    var query = client
        .from('leave_requests')
        .select('*, teachers(profiles!teachers_profile_id_fkey(full_name))')
        .eq('school_id', await schoolId());
    if (mine) query = query.eq('teacher_id', await requireTeacherId());
    return (await query.order(
      'created_at',
      ascending: false,
    )).map(DbRow.from).toList();
  }

  Future<void> requestLeave(DateTime start, DateTime end, String reason) =>
      rpc('request_leave', {
        'start_day': SchoolDatabase.date(start),
        'end_day': SchoolDatabase.date(end),
        'leave_reason': reason.trim(),
      });
  Future<void> reviewLeave(String id, bool approve, String reason) => rpc(
    'review_leave',
    {'request_id': id, 'approve_request': approve, 'review_reason': reason},
  );

  Future<List<DbRow>> replacements({DateTime? date, bool mine = false}) async {
    var query = client
        .from('replacement_assignments')
        .select(
          '*, absent_teacher:teachers!absent_teacher_id(profiles!teachers_profile_id_fkey(full_name)), replacement_teacher:teachers!replacement_teacher_id(profiles!teachers_profile_id_fkey(full_name)), timetables(weekday,period_id,school_classes(name),subjects(name),periods(*))',
        )
        .eq('school_id', await schoolId())
        .eq('status', 'assigned');
    if (date != null) {
      query = query.eq('assignment_date', SchoolDatabase.date(date));
    }
    if (mine) {
      query = query.eq('replacement_teacher_id', await requireTeacherId());
    }
    return (await query.order(
      'assignment_date',
      ascending: false,
    )).map(DbRow.from).toList();
  }

  Future<List<DbRow>> uncovered(DateTime date) async {
    final attendance = await teacherAttendance(date);
    final absent = attendance
        .where((r) => ['absent', 'leave'].contains(r['status']))
        .map((r) => r['teacher_id'])
        .toSet();
    final covers = await replacements(date: date);
    final covered = covers.map((r) => r['timetable_id']).toSet();
    final slots = await timetable(
      weekday: DateFormat('EEEE', 'en').format(date),
      date: date,
    );
    return slots
        .where(
          (s) => absent.contains(s['teacher_id']) && !covered.contains(s['id']),
        )
        .toList();
  }

  Future<List<DbRow>> candidates(DbRow slot, DateTime date) async {
    final result = await client.rpc(
      'replacement_candidates',
      params: {
        'target_slot': slot['id'],
        'target_date': SchoolDatabase.date(date),
      },
    );
    return (result as List).map((r) => DbRow.from(r as Map)).toList();
  }

  Future<void> assignReplacement(String slot, String teacher, DateTime date) =>
      rpc('assign_replacement', {
        'target_slot': slot,
        'cover_teacher': teacher,
        'target_date': SchoolDatabase.date(date),
      });

  Future<DbRow> autoAssignReplacements(DateTime date) async {
    final result = await client.rpc(
      'auto_assign_replacements',
      params: {'target_date': SchoolDatabase.date(date)},
    );
    SchoolDatabase.changed();
    return DbRow.from(result as Map);
  }

  Future<void> cancelReplacement(String id) =>
      rpc('cancel_replacement', {'assignment_id': id});

  Future<List<DbRow>> timetableUploads() => rows(
    'timetable_uploads',
    select: '*,teachers(profiles!teachers_profile_id_fkey(full_name))',
    order: 'created_at',
  );

  Future<DbRow> uploadTimetableFile(
    String teacher,
    String name,
    String mime,
    Uint8List bytes,
  ) async {
    if (!await isPrincipal() && await requireTeacherId() != teacher) {
      throw StateError('Upload your own timetable.');
    }
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw StateError('Choose a Photo/PDF file up to 10 MB.');
    }
    final sid = await schoolId();
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '$sid/$teacher/${DateTime.now().microsecondsSinceEpoch}/$safeName';
    final bucket = client.storage.from('timetable-files');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mime),
    );
    try {
      final record = await client
          .from('timetable_uploads')
          .insert({
            'school_id': sid,
            'teacher_id': teacher,
            'uploaded_by': client.auth.currentUser!.id,
            'file_name': name,
            'storage_path': path,
            'mime_type': mime,
          })
          .select()
          .single();
      SchoolDatabase.changed();
      return record;
    } catch (_) {
      // Remove only this unreferenced new object; retain the original database error.
      try {
        await bucket.remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  Future<Uint8List> timetableFile(DbRow upload) =>
      client.storage.from('timetable-files').download(upload['storage_path']);

  Future<void> publishTimetable(
    DbRow upload,
    List<DbRow> entries,
    DateTime from,
    bool dateOnly,
  ) => rpc('publish_teacher_timetable', {
    'upload_id': upload['id'],
    'entries': entries,
    'effective_date': SchoolDatabase.date(from),
    'date_only': dateOnly,
  });

  Future<void> submitTimetable(
    DbRow upload,
    List<DbRow> entries,
    DateTime from,
    bool dateOnly,
  ) => rpc('submit_timetable_document', {
    'upload_id': upload['id'],
    'entries': entries,
    'effective_date': SchoolDatabase.date(from),
    'date_only': dateOnly,
  });

  Future<List<DbRow>> notifications() async =>
      (await client
              .from('notifications')
              .select()
              .eq('school_id', await schoolId())
              .eq('recipient_id', client.auth.currentUser!.id)
              .order('created_at', ascending: false))
          .map(DbRow.from)
          .toList();
  Future<void> readNotifications({String? id}) async {
    var query = client
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', client.auth.currentUser!.id);
    if (id != null) query = query.eq('id', id);
    await query;
    SchoolDatabase.changed();
  }

  Future<void> announce(String title, String body) => rpc('send_announcement', {
    'announcement_title': title,
    'announcement_body': body,
  });

  Future<List<DbRow>> events() =>
      rows('school_calendar', order: 'calendar_date');

  Future<DbRow> dashboard({bool teacher = false}) async {
    final me = await profile();
    final staff = await teachers();
    final groups = await classes();
    final pupils = await rows('students');
    final myId = teacher ? await requireTeacherId() : null;
    final slots = await timetable(
      teacher: myId,
      weekday: DateFormat('EEEE', 'en').format(SchoolDatabase.now),
    );
    final att = teacher
        ? <DbRow>[]
        : await teacherAttendance(SchoolDatabase.now);
    final leave = await leaves(mine: teacher);
    final covers = await replacements(date: SchoolDatabase.now, mine: teacher);
    final myClassIds = teacher
        ? (await timetable(teacher: myId)).map((s) => s['class_id']).toSet()
        : groups.map((g) => g['id']).toSet();
    return {
      'profile': me,
      'teachers': staff
          .where((t) => t['profiles']?['is_active'] == true)
          .length,
      'classes': myClassIds.length,
      'students': pupils
          .where(
            (s) => s['is_active'] == true && myClassIds.contains(s['class_id']),
          )
          .length,
      'slots': slots,
      'attendance': att,
      'leaves': leave.where((l) => l['status'] == 'pending').length,
      'covers': covers.length,
      'uncovered': teacher
          ? 0
          : slots
                .where(
                  (slot) =>
                      att.any(
                        (r) =>
                            r['teacher_id'] == slot['teacher_id'] &&
                            ['absent', 'leave'].contains(r['status']),
                      ) &&
                      !covers.any((r) => r['timetable_id'] == slot['id']),
                )
                .length,
      'my_attendance': teacher ? await myAttendance() : null,
    };
  }

  Future<DbRow> report(DateTime month) async {
    final start = SchoolDatabase.date(DateTime(month.year, month.month));
    final end = SchoolDatabase.date(DateTime(month.year, month.month + 1));
    final sid = await schoolId();
    final attendance = await readAll(
      client
          .from('attendance')
          .select('status')
          .eq('school_id', sid)
          .gte('attendance_date', start)
          .lt('attendance_date', end),
    );
    final present = attendance
        .where((r) => ['present', 'late'].contains(r['status']))
        .length;
    final leave = await readAll(
      client
          .from('leave_requests')
          .select('status')
          .eq('school_id', sid)
          .gte('start_date', start)
          .lt('start_date', end),
    );
    final covers = await readAll(
      client
          .from('replacement_assignments')
          .select(
            'replacement_teacher_id,teachers!replacement_teacher_id(profiles!teachers_profile_id_fkey(full_name))',
          )
          .eq('status', 'assigned')
          .eq('school_id', sid)
          .gte('assignment_date', start)
          .lt('assignment_date', end),
    );
    final workloads = <String, DbRow>{};
    for (final c in covers) {
      final id = c['replacement_teacher_id'] as String;
      workloads.putIfAbsent(
        id,
        () => {
          'name': c['teachers']?['profiles']?['full_name'] ?? '',
          'count': 0,
        },
      );
      workloads[id]!['count'] = (workloads[id]!['count'] as int) + 1;
    }
    return {
      'attendance_records': attendance.length,
      'rate': attendance.isEmpty
          ? null
          : (present / attendance.length * 100).round(),
      'absent': attendance.where((r) => r['status'] == 'absent').length,
      'leaves': leave.length,
      'covers': covers.length,
      'workloads': workloads.values.toList(),
    };
  }
}
