import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:schoolsync/core/data/school_repository.dart';

void main() {
  late SupabaseClient client;
  late SchoolRepository repository;
  final requests = <http.Request>[];
  var failTable = '';
  var attendance = <Map<String, dynamic>>[];
  var teachers = <Map<String, dynamic>>[];
  var classes = <Map<String, dynamic>>[];
  setUp(() async {
    requests.clear();
    failTable = '';
    attendance = [];
    teachers = [];
    classes = [];
    final jwt =
        '${_part({'alg': 'HS256'})}.${_part({'sub': 'user-1', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.signature';
    client = SupabaseClient(
      'https://test.supabase.co',
      'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode({
              'access_token': jwt,
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'user-1',
                'aud': 'authenticated',
                'email': 'test@example.org',
                'created_at': '2026-01-01T00:00:00Z',
              },
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        final table = request.url.pathSegments.last;
        if (table == failTable) {
          return http.Response(
            jsonEncode({'message': 'Permission denied', 'code': '42501'}),
            403,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (table == 'profiles') {
          return http.Response(
            jsonEncode({
              'id': 'user-1',
              'school_id': 'school-1',
              'is_active': true,
              'role': 'principal',
              'full_name': 'Test Principal',
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (table == 'attendance') {
          return http.Response(
            jsonEncode(attendance),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (table == 'school_classes') {
          final offset = int.parse(
            request.url.queryParameters['offset'] ?? '0',
          );
          final limit = int.parse(
            request.url.queryParameters['limit'] ?? '1000',
          );
          return http.Response(
            jsonEncode(classes.skip(offset).take(limit).toList()),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (table == 'teachers') {
          return http.Response(
            jsonEncode(teachers),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '[]',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await client.auth.signInWithPassword(
      email: 'test@example.org',
      password: 'test-password',
    );
    repository = SchoolRepository(client: client);
  });
  tearDown(() async => client.dispose());

  test(
    'school lists include records beyond Supabase response limits',
    () async {
      classes = List.generate(
        1248,
        (i) => {'id': 'class-$i', 'name': 'Test class $i'},
      );
      final result = await repository.classes();
      expect(result.length, 1248);
      expect(result.last['id'], 'class-1247');
      expect(
        requests
            .where((r) => r.url.pathSegments.last == 'school_classes')
            .length,
        3,
      );
    },
  );

  test('empty reports have no invented attendance rate or counts', () async {
    final data = await repository.report(DateTime(2026, 11));
    expect(data['rate'], isNull);
    expect(data['attendance_records'], 0);
    expect(data['leaves'], 0);
    expect(data['covers'], 0);
    final reads = requests.where(
      (r) =>
          r.url.path.startsWith('/rest/v1/') &&
          r.url.pathSegments.last != 'profiles',
    );
    expect(
      reads.every((r) => r.url.queryParameters['school_id'] == 'eq.school-1'),
      isTrue,
    );
    expect(
      reads.every(
        (r) =>
            r.url.queryParameters['start_date'] != null ||
            r.url.queryParameters['attendance_date'] != null ||
            r.url.queryParameters['assignment_date'] != null,
      ),
      isTrue,
    );
  });

  test('unmarked teacher attendance is not fabricated as absence', () async {
    teachers = [
      {
        'id': 't1',
        'profiles': {'full_name': 'Test Teacher', 'is_active': true},
      },
      {
        'id': 't2',
        'profiles': {'full_name': 'Inactive', 'is_active': false},
      },
    ];
    final data = await repository.teacherAttendance(DateTime(2026, 11, 6));
    expect(data.length, 1);
    expect(data.single['status'], 'unmarked');
  });

  test(
    'database permissions failures propagate rather than looking empty',
    () async {
      failTable = 'school_classes';
      await expectLater(
        repository.classes(),
        throwsA(isA<PostgrestException>()),
      );
    },
  );

  test('monthly rate derives from saved records only', () async {
    attendance = [
      {'status': 'present'},
      {'status': 'late'},
      {'status': 'absent'},
      {'status': 'leave'},
    ];
    final data = await repository.report(DateTime(2026, 11));
    expect(data['rate'], 50);
    expect(data['attendance_records'], 4);
    expect(data['absent'], 1);
  });
}

String _part(Map<String, dynamic> data) =>
    base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
