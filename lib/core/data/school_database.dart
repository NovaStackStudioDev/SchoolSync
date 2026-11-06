import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef DbRow = Map<String, dynamic>;

/// All school data is read from Supabase. Errors deliberately reach the UI.
class SchoolDatabase {
  SchoolDatabase({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;
  static final changes = ValueNotifier<int>(0);
  static void changed() => changes.value++;
  static DateTime get now =>
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  static String date(DateTime value) => DateFormat('yyyy-MM-dd').format(value);
  static String get today => date(now);

  Future<DbRow> profile() async {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Please sign in again.');
    final result = await client.from('profiles').select().eq('id', id).single();
    if (result['is_active'] != true) {
      throw StateError('This account is inactive.');
    }
    return result;
  }

  Future<String> schoolId() async => (await profile())['school_id'] as String;
  Future<bool> isPrincipal() async => (await profile())['role'] == 'principal';
  Future<void> requirePrincipal() async {
    if (!await isPrincipal()) {
      throw StateError('Only a principal can change this.');
    }
  }

  Future<List<DbRow>> rows(
    String table, {
    String select = '*',
    String? order,
  }) async {
    final query = client
        .from(table)
        .select(select)
        .eq('school_id', await schoolId());
    return readAll(order == null ? query : query.order(order));
  }

  /// Supabase limits each response; follow pages so totals use every record.
  Future<List<DbRow>> readAll(
    PostgrestTransformBuilder<List<DbRow>> query,
  ) async {
    const pageSize = 500;
    final result = <DbRow>[];
    while (true) {
      final page = await query
          .order('id')
          .range(result.length, result.length + pageSize - 1);
      result.addAll(page);
      if (page.length < pageSize) return result;
    }
  }

  Future<void> save(
    String table,
    DbRow values, {
    String? id,
    bool principalOnly = true,
  }) async {
    if (principalOnly) await requirePrincipal();
    final sid = await schoolId();
    if (id == null) {
      await client.from(table).insert({...values, 'school_id': sid});
    } else {
      await client.from(table).update(values).eq('id', id).eq('school_id', sid);
    }
    changed();
  }

  Future<String?> teacherId() async {
    final result = await client
        .from('teachers')
        .select('id')
        .eq('profile_id', client.auth.currentUser!.id)
        .eq('school_id', await schoolId())
        .maybeSingle();
    return result?['id'] as String?;
  }

  Future<String> requireTeacherId() async {
    final id = await teacherId();
    if (id == null) {
      throw StateError(
        'Your teacher record is missing. Please contact the principal.',
      );
    }
    return id;
  }

  Future<void> rpc(String name, DbRow params) async {
    await client.rpc(name, params: params);
    changed();
  }
}
