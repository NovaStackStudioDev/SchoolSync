import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/teacher.dart';

class TeacherRepository {
  TeacherRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Teacher>> listTeachers() async {
    try {
      final rows = await _client.from('teachers').select(
            'id, employee_number, phone, profiles(full_name, is_active), teacher_subjects(subjects(name))',
          );

      final teachers = (rows as List<dynamic>).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final profile = row['profiles'] is Map
            ? Map<String, dynamic>.from(row['profiles'] as Map)
            : const <String, dynamic>{};
        final links = row['teacher_subjects'];
        final subjects = <String>[];
        if (links is List) {
          for (final link in links) {
            if (link is Map && link['subjects'] is Map) {
              final name = link['subjects']['name'];
              if (name is String && name.isNotEmpty) subjects.add(name);
            }
          }
        }
        return Teacher(
          id: row['id'] as String,
          employeeNumber: (row['employee_number'] as String?) ?? '',
          fullName: (profile['full_name'] as String?) ?? 'Teacher',
          subjects: subjects,
          isActive: profile['is_active'] != false,
          phone: row['phone'] as String?,
        );
      }).toList();

      teachers.sort((a, b) => a.fullName.compareTo(b.fullName));
      return teachers;
    } catch (_) {
      return [];
    }
  }

  Future<Teacher?> getCurrentTeacher() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final row = await _client
          .from('teachers')
          .select(
            'id, employee_number, phone, profiles(full_name, is_active), teacher_subjects(subjects(name))',
          )
          .eq('profile_id', user.id)
          .maybeSingle();

      if (row == null) return null;

      final profile = row['profiles'] is Map
          ? Map<String, dynamic>.from(row['profiles'] as Map)
          : const <String, dynamic>{};
      final links = row['teacher_subjects'];
      final subjects = <String>[];
      if (links is List) {
        for (final link in links) {
          if (link is Map && link['subjects'] is Map) {
            final name = link['subjects']['name'];
            if (name is String && name.isNotEmpty) subjects.add(name);
          }
        }
      }

      return Teacher(
        id: row['id'] as String,
        employeeNumber: (row['employee_number'] as String?) ?? '',
        fullName: (profile['full_name'] as String?) ?? 'Teacher',
        subjects: subjects,
        isActive: profile['is_active'] != false,
        phone: row['phone'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> getCurrentTeacherId() async {
    final teacher = await getCurrentTeacher();
    return teacher?.id;
  }

  Future<List<String>> subjectsForCurrentUser() async {
    final teacher = await getCurrentTeacher();
    return teacher?.subjects ?? const [];
  }
}
