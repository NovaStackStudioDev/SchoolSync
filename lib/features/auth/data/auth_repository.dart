import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../core/models/user_role.dart';

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
  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<void> login({
    required String email,
    required String password,
    UserRole? expectedRole,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final profile = await getProfile();
      if (expectedRole != null && profile?['role'] != expectedRole.name) {
        await logout();
        throw AppAuthException(
          'wrong_role',
          'Please select your assigned ${profile?['role'] ?? 'staff'} role.',
        );
      }
    } on AuthException catch (e) {
      throw _map(e);
    }
  }

  Future<RegisterResult> registerTeacher({
    required String fullName,
    required String email,
    required String password,
    required List<String> subjects,
    String? phone,
    String? employeeNumber,
  }) async {
    try {
      final response = await _client.auth.signUp(
        emailRedirectTo: kIsWeb ? Uri.base.origin : 'lk.schoolsync://auth',
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'role': 'teacher',
          'subjects': subjects,
          'phone': phone?.trim(),
          'employee_number': employeeNumber?.trim(),
        },
      );
      if (response.user?.identities?.isEmpty == true) {
        throw const AppAuthException('already_registered');
      }
      if (response.session != null) await provisionTeacherFromMetadata();
      return RegisterResult(needsEmailConfirmation: response.session == null);
    } on AuthException catch (e) {
      throw _map(e);
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    // Existing accounts do not depend on the registration provisioning RPC.
    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) {
      if (existing['role'] == 'teacher' && existing['is_active'] == true) {
        final teacher = await _client
            .from('teachers')
            .select('id')
            .eq('profile_id', user.id)
            .maybeSingle();
        if (teacher == null) await provisionTeacherFromMetadata();
      }
      return existing;
    }
    await provisionTeacherFromMetadata();
    return _client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();
  }

  Future<void> provisionTeacherFromMetadata() async {
    if (currentUser == null) return;
    try {
      await _client.rpc('provision_teacher');
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202') {
        throw const AppAuthException(
          'database_setup_missing',
          'Your sign-in/account was accepted, but the school database setup is incomplete. '
              'Run supabase/repair_sign_in.sql in this project’s Supabase SQL Editor, then retry. '
              'You do not need to register again or change your password.',
        );
      }
      rethrow;
    }
  }

  Future<void> logout() => _client.auth.signOut();
  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb ? Uri.base.origin : 'lk.schoolsync://auth',
      );
  AppAuthException _map(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('already')) {
      return const AppAuthException('already_registered');
    }
    if (m.contains('confirm')) {
      return const AppAuthException('email_not_confirmed');
    }
    if (m.contains('invalid') || m.contains('credential')) {
      return const AppAuthException('invalid_credentials');
    }
    if (m.contains('password')) {
      return AppAuthException('weak_password', e.message);
    }
    return AppAuthException('unknown', e.message);
  }
}
