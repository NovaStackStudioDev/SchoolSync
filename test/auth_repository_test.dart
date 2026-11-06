import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:schoolsync/features/auth/data/auth_repository.dart';
import 'package:schoolsync/core/models/user_role.dart';

void main() {
  late SupabaseClient client;
  var hasProfile = true;
  var badPassword = false;
  final paths = <String>[];
  setUp(() {
    paths.clear();
    hasProfile = true;
    badPassword = false;
    final token =
        '${_part({'alg': 'HS256'})}.${_part({'sub': 'test-user', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.signature';
    client = SupabaseClient(
      'https://test.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        final path = request.url.path;
        Object? body;
        var status = 200;
        if (path == '/auth/v1/token') {
          body = badPassword
              ? {'msg': 'Invalid login credentials'}
              : {
                  'access_token': token,
                  'refresh_token': 'refresh',
                  'expires_in': 3600,
                  'token_type': 'bearer',
                  'user': {
                    'id': 'test-user',
                    'aud': 'authenticated',
                    'email': 'teacher@example.org',
                    'created_at': '2026-01-01T00:00:00Z',
                  },
                };
          if (badPassword) status = 400;
        } else if (path == '/rest/v1/profiles') {
          body = hasProfile
              ? {
                  'id': 'test-user',
                  'role': 'teacher',
                  'school_id': 'school',
                  'full_name': 'Test Teacher',
                  'is_active': true,
                }
              : null;
        } else if (path == '/rest/v1/teachers') {
          body = {'id': 'test-teacher'};
        } else if (path == '/rest/v1/rpc/provision_teacher') {
          body = {
            'code': 'PGRST202',
            'message': 'Could not find function public.provision_teacher',
            'details': null,
            'hint': null,
          };
          status = 404;
        }
        return http.Response(
          jsonEncode(body),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  tearDown(() async => client.dispose());
  test(
    'existing teacher can log in when the registration RPC is missing',
    () async {
      await AuthRepository(client: client).login(
        email: 'teacher@example.org',
        password: 'valid-password',
        expectedRole: UserRole.teacher,
      );
      expect(client.auth.currentUser, isNotNull);
      expect(paths.where((p) => p.endsWith('/rpc/provision_teacher')), isEmpty);
    },
  );
  test(
    'missing profile and RPC reports school setup, not invalid credentials',
    () async {
      hasProfile = false;
      await expectLater(
        AuthRepository(client: client)
            .login(email: 'teacher@example.org', password: 'valid-password'),
        throwsA(
          isA<AppAuthException>()
              .having((e) => e.code, 'code', 'database_setup_missing')
              .having(
                (e) => e.detail,
                'instructions',
                contains('repair_sign_in.sql'),
              ),
        ),
      );
      expect(client.auth.currentUser, isNotNull);
    },
  );
  test('an actual bad password still reports invalid credentials', () async {
    badPassword = true;
    await expectLater(
      AuthRepository(client: client)
          .login(email: 'teacher@example.org', password: 'bad'),
      throwsA(
        isA<AppAuthException>().having(
          (e) => e.code,
          'code',
          'invalid_credentials',
        ),
      ),
    );
    expect(paths.where((p) => p.startsWith('/rest/')), isEmpty);
  });
}

String _part(Map<String, dynamic> data) =>
    base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
