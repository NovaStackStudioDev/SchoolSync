import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';

class AttendanceOverviewScreen extends StatefulWidget {
  const AttendanceOverviewScreen({super.key});
  @override
  State<AttendanceOverviewScreen> createState() =>
      _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState extends State<AttendanceOverviewScreen> {
  DateTime _date = SchoolDatabase.now;
  final _db = SchoolRepository();
  final _busy = <String>{};
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'Teacher Attendance'),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(DateFormat('EEE, d MMM yyyy').format(_date)),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: SchoolDatabase.now,
              );
              if (date != null && mounted) setState(() => _date = date);
            },
          ),
        ),
        Expanded(
          child: LiveData<List<DbRow>>(
            key: ValueKey(SchoolDatabase.date(_date)),
            load: () => _db.teacherAttendance(_date),
            builder: (context, records) => ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final status in [
                      'present',
                      'absent',
                      'late',
                      'leave',
                      'unmarked',
                    ])
                      Chip(
                        label: Text(
                          '$status ${records.where((r) => r['status'] == status).length}',
                        ),
                      ),
                  ],
                ),
                if (records.isEmpty)
                  const NoRecords(
                    message: 'No active teachers in your school.',
                  ),
                for (final record in records)
                  Card(
                    child: ListTile(
                      title: Text(record['full_name'] ?? ''),
                      subtitle: record['marked_at'] == null
                          ? null
                          : Text(
                              'Marked ${DateFormat('HH:mm').format(DateTime.parse(record['marked_at']).toUtc().add(const Duration(hours: 5, minutes: 30)))}',
                            ),
                      trailing: DropdownButton<String>(
                        value: record['status'],
                        underline: const SizedBox.shrink(),
                        items:
                            [
                                  'unmarked',
                                  'pending',
                                  'present',
                                  'absent',
                                  'late',
                                  'leave',
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    enabled: ![
                                      'unmarked',
                                      'pending',
                                    ].contains(s),
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: _busy.contains(record['teacher_id'])
                            ? null
                            : (value) async {
                                if (value == null ||
                                    ['unmarked', 'pending'].contains(value)) {
                                  return;
                                }
                                setState(() => _busy.add(record['teacher_id']));
                                await runAction(
                                  context,
                                  () => _db.setTeacherAttendance(
                                    record['teacher_id'],
                                    _date,
                                    value,
                                  ),
                                  success: 'Attendance updated.',
                                );
                                if (mounted) {
                                  setState(
                                    () => _busy.remove(record['teacher_id']),
                                  );
                                }
                              },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
