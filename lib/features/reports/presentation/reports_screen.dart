import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';
import '../../../core/widgets/module_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _month = DateTime(SchoolDatabase.now.year, SchoolDatabase.now.month);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'Reports & Analytics'),
    body: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_month),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed:
                  _month.year == SchoolDatabase.now.year &&
                      _month.month == SchoolDatabase.now.month
                  ? null
                  : () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1),
                    ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Expanded(
          child: LiveData<DbRow>(
            key: ValueKey(_month),
            load: () => SchoolRepository().report(_month),
            builder: (context, report) => ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  children: [
                    StatCard(
                      label: 'Attendance Rate',
                      value: report['rate'] == null
                          ? '—'
                          : '${report['rate']}%',
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(width: 12),
                    StatCard(
                      label: 'Recorded Absences',
                      value: '${report['absent']}',
                      icon: Icons.person_off_outlined,
                      color: AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatCard(
                      label: 'Leave Requests',
                      value: '${report['leaves']}',
                      icon: Icons.event_note_outlined,
                    ),
                    const SizedBox(width: 12),
                    StatCard(
                      label: 'Cover Periods',
                      value: '${report['covers']}',
                      icon: Icons.swap_horiz,
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Attendance rate uses ${report['attendance_records']} saved teacher attendance records for this month. Unmarked attendance is excluded.',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SectionTitle('Cover Workload'),
                if ((report['workloads'] as List).isEmpty)
                  const NoRecords(
                    message: 'No cover assignments recorded this month.',
                  ),
                for (final workload in report['workloads'])
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: AppColors.greenDark,
                      ),
                      title: Text(workload['name']),
                      trailing: Text(
                        '${workload['count']} periods',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy Monthly Summary'),
                  onPressed: () => runAction(
                    context,
                    () => Clipboard.setData(
                      ClipboardData(
                        text:
                            'SchoolSync — ${DateFormat('MMMM yyyy').format(_month)}\nAttendance rate: ${report['rate'] == null ? 'No records' : '${report['rate']}%'}\nAttendance records: ${report['attendance_records']}\nRecorded absences: ${report['absent']}\nLeave requests: ${report['leaves']}\nCover periods: ${report['covers']}\n${(report['workloads'] as List).map((w) => '${w['name']}: ${w['count']} covers').join('\n')}',
                      ),
                    ),
                    success: 'Summary copied.',
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
