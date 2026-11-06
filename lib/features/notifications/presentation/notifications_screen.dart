import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';
import '../../../core/widgets/record_form.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _db = SchoolRepository();
  String _filter = 'All';
  bool _saving = false;
  Future<DbRow> _load() async => {
    'items': await _db.notifications(),
    'principal': await _db.isPrincipal(),
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'Notifications'),
    body: LiveData<DbRow>(
      load: _load,
      builder: (context, data) {
        final items = (data['items'] as List)
            .where(
              (n) =>
                  _filter == 'All' ||
                  (_filter == 'Unread'
                      ? n['is_read'] != true
                      : n['kind'] == 'announcement'),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final filter in ['All', 'Unread', 'Announcements'])
                  ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        await runAction(context, () => _db.readNotifications());
                        if (mounted) setState(() => _saving = false);
                      },
                child: const Text('Mark all as read'),
              ),
            ),
            if (items.isEmpty)
              const NoRecords(message: 'You’re all caught up.'),
            for (final item in items)
              Card(
                child: ListTile(
                  leading: Icon(
                    item['kind'] == 'announcement'
                        ? Icons.campaign_outlined
                        : Icons.notifications_outlined,
                    color: AppColors.greenDark,
                  ),
                  title: Text(
                    item['title'],
                    style: TextStyle(
                      fontWeight: item['is_read'] == true
                          ? FontWeight.w500
                          : FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${item['message']}\n${DateFormat('d MMM, HH:mm').format(DateTime.parse(item['created_at']).toUtc().add(const Duration(hours: 5, minutes: 30)))}',
                  ),
                  isThreeLine: true,
                  trailing: item['is_read'] == true
                      ? null
                      : const Icon(
                          Icons.circle,
                          size: 8,
                          color: AppColors.greenDark,
                        ),
                  onTap: () => runAction(
                    context,
                    () => _db.readNotifications(id: item['id']),
                  ),
                ),
              ),
            if (data['principal'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FilledButton.icon(
                  icon: const Icon(Icons.campaign),
                  label: const Text('New Announcement'),
                  onPressed: () => editRecord(
                    context,
                    title: 'School Announcement',
                    fields: const [
                      FieldSpec('title', 'Title'),
                      FieldSpec('message', 'Message'),
                    ],
                    save: (v) => _db.announce(v['title'], v['message']),
                    button: 'Send Announcement',
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
