import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';

class AppAuthException implements Exception {
  const AppAuthException(this.code, [this.detail]);

  final String code;
  final String? detail;

  @override
  String toString() => detail ?? code;
}

class RegisterResult {
  const RegisterResult({required this.needsEmailConfirmation});

  final bool needsEmailConfirmation;
}

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw _mapAuth(error);
    }
    await provisionTeacherFromMetadata();
  }

  Future<RegisterResult> registerTeacher({
    required String fullName,
    required String email,
    required String password,
    required List<String> subjects,
    String? phone,
    String? employeeNumber,
  }) async {
    AuthResponse response;
    try {
      response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'role': 'teacher',
          'subjects': subjects,
          'phone': (phone ?? '').trim(),
          'employee_number': (employeeNumber ?? '').trim(),
        },
      );
    } on AuthException catch (error) {
      throw _mapAuth(error);
    }

    final identities = response.user?.identities;
    if (response.user != null && (identities == null || identities.isEmpty)) {
      throw const AppAuthException('already_registered');
    }

    if (response.session != null) {
      await provisionTeacherFromMetadata();
      return const RegisterResult(needsEmailConfirmation: false);
    }

    return const RegisterResult(needsEmailConfirmation: true);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final existing = await _fetchProfile(user.id);
    if (existing != null) return existing;

    await provisionTeacherFromMetadata();
    return _fetchProfile(user.id);
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) {
    return _client
        .from('profiles')
        .select('id, full_name, role, school_id, is_active')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> provisionTeacherFromMetadata() async {
    final user = currentUser;
    if (user == null) return;

    final existing = await _fetchProfile(user.id);
    if (existing != null) return;

    final meta = user.userMetadata ?? {};
    if (meta['role'] != 'teacher') return;

    final schoolId = await _ensureSchool();
    final subjects = _subjectCodes(meta['subjects']);
    final employee = (meta['employee_number'] as String?)?.trim();
    final phone = (meta['phone'] as String?)?.trim();

    await _client.from('profiles').insert({
      'id': user.id,
      'full_name': (meta['full_name'] as String?)?.trim().isNotEmpty == true
          ? (meta['full_name'] as String).trim()
          : 'Teacher',
      'role': 'teacher',
      'school_id': schoolId,
      'is_active': true,
    });

    final teacher = await _client
        .from('teachers')
        .insert({
          'profile_id': user.id,
          'school_id': schoolId,
          'employee_number': (employee == null || employee.isEmpty)
              ? 'T-${user.id.substring(0, 8).toUpperCase()}'
              : employee,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        })
        .select('id')
        .single();

    for (final name in subjects) {
      final subjectId = await _ensureSubject(schoolId, name);
      await _client.from('teacher_subjects').insert({
        'teacher_id': teacher['id'],
        'subject_id': subjectId,
      });
    }
  }

  Future<String> _ensureSchool() async {
    final found = await _client
        .from('schools')
        .select('id')
        .eq('name', AppConstants.schoolName)
        .limit(1);
    if (found.isNotEmpty) return found.first['id'] as String;

    final created = await _client
        .from('schools')
        .insert({
          'name': AppConstants.schoolName,
          'timezone': AppConstants.timezone,
        })
        .select('id')
        .single();
    return created['id'] as String;
  }

  Future<String> _ensureSubject(String schoolId, String name) async {
    final found = await _client
        .from('subjects')
        .select('id')
        .eq('school_id', schoolId)
        .eq('name', name)
        .limit(1);
    if (found.isNotEmpty) return found.first['id'] as String;

    final created = await _client
        .from('subjects')
        .insert({'school_id': schoolId, 'name': name})
        .select('id')
        .single();
    return created['id'] as String;
  }

  List<String> _subjectCodes(Object? raw) {
    if (raw is List) {
      return raw.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) return [raw.trim()];
    return const [];
  }

  AppAuthException _mapAuth(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('already')) {
      return const AppAuthException('already_registered');
    }
    if (message.contains('confirm')) {
      return const AppAuthException('email_not_confirmed');
    }
    if (message.contains('invalid') || message.contains('credential')) {
      return const AppAuthException('invalid_credentials');
    }
    if (message.contains('password')) {
      return AppAuthException('weak_password', error.message);
    }
    return AppAuthException('unknown', error.message);
  }
}
