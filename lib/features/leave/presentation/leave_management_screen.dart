import 'package:flutter/material.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';
import '../../../core/widgets/record_form.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});
  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final _db = SchoolRepository();
  String _filter = 'pending';
  final _busy = <String>{};
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'Leave Requests'),
    body: LiveData<List<DbRow>>(
      load: _db.leaves,
      builder: (context, leaves) => ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final status in ['pending', 'approved', 'rejected'])
                ChoiceChip(
                  label: Text(
                    '${status[0].toUpperCase()}${status.substring(1)} (${leaves.where((l) => l['status'] == status).length})',
                  ),
                  selected: _filter == status,
                  onSelected: (_) => setState(() => _filter = status),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!leaves.any((l) => l['status'] == _filter))
            NoRecords(message: 'No $_filter leave requests.'),
          for (final leave in leaves.where((l) => l['status'] == _filter))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave['teachers']?['profiles']?['full_name'] ?? '',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${leave['start_date']} – ${leave['end_date']}'),
                    const SizedBox(height: 6),
                    Text(leave['reason']),
                    if (leave['rejection_reason'] != null)
                      Text('Reason: ${leave['rejection_reason']}'),
                    if (_filter == 'pending') ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _busy.contains(leave['id'])
                                  ? null
                                  : () => editRecord(
                                      context,
                                      title: 'Reject Leave',
                                      fields: const [
                                        FieldSpec(
                                          'reason',
                                          'Reason for rejection',
                                        ),
                                      ],
                                      save: (v) => _db.reviewLeave(
                                        leave['id'],
                                        false,
                                        v['reason'],
                                      ),
                                      button: 'Reject Request',
                                    ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: _busy.contains(leave['id'])
                                  ? null
                                  : () async {
                                      setState(() => _busy.add(leave['id']));
                                      await runAction(
                                        context,
                                        () => _db.reviewLeave(
                                          leave['id'],
                                          true,
                                          '',
                                        ),
                                        success: 'Leave approved. Attendance updated for working days.',
                                      );
                                      if (mounted) {
                                        setState(
                                          () => _busy.remove(leave['id']),
                                        );
                                      }
                                    },
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
