import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/timetable.dart';

class NotificationRepository {
  NotificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<AppNotification>> getNotifications() async {
    try {
      final rows = await _client
          .from('notifications')
          .select('id, title, message, is_read, created_at')
          .order('created_at', ascending: false);

      return (rows as List).map((r) => AppNotification.fromMap(Map<String, dynamic>.from(r as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('is_read', false);
    } catch (_) {}
  }

  Future<void> sendNotification({
    required String title,
    required String message,
  }) async {
    try {
      await _client.from('notifications').insert({
        'title': title,
        'message': message,
        'is_read': false,
      });
    } catch (_) {}
  }
}

