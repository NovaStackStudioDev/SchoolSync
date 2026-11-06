import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});
  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _db = SchoolRepository();
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();
  DateTimeRange? _range;
  bool _saving = false;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'Request Leave'),
    body: LiveData<List<DbRow>>(
      load: () => _db.leaves(mine: true),
      builder: (context, leaves) => ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            'Select your leave dates and send a reason to the principal.',
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(
              _range == null
                  ? 'Choose Dates'
                  : '${DateFormat('d MMM').format(_range!.start)} – ${DateFormat('d MMM').format(_range!.end)}',
            ),
            onPressed: _saving
                ? null
                : () async {
                    final today = SchoolDatabase.now;
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(today.year, today.month, today.day),
                      lastDate: today.add(const Duration(days: 365)),
                    );
                    if (range != null && mounted) {
                      setState(() => _range = range);
                    }
                  },
          ),
          const SizedBox(height: 16),
          Form(
            key: _form,
            child: TextFormField(
              controller: _reason,
              enabled: !_saving,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason *'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter a reason' : null,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            icon: const Icon(Icons.send_outlined),
            label: Text(_saving ? 'Submitting…' : 'Submit Request'),
            onPressed: _saving
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    if (_range == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Choose your leave dates.'),
                        ),
                      );
                      return;
                    }
                    setState(() => _saving = true);
                    final ok = await runAction(
                      context,
                      () => _db.requestLeave(
                        _range!.start,
                        _range!.end,
                        _reason.text,
                      ),
                      success: 'Leave request submitted.',
                    );
                    if (mounted) {
                      setState(() {
                        _saving = false;
                        if (ok) {
                          _range = null;
                          _reason.clear();
                        }
                      });
                    }
                  },
          ),
          const SectionTitle('Leave History'),
          if (leaves.isEmpty)
            const NoRecords(
              message: 'You haven’t submitted any leave requests.',
            ),
          for (final leave in leaves)
            Card(
              child: ListTile(
                title: Text(leave['reason']),
                subtitle: Text(
                  '${leave['start_date']} – ${leave['end_date']}${leave['rejection_reason'] == null ? '' : '\n${leave['rejection_reason']}'}',
                ),
                trailing: Chip(label: Text(leave['status'])),
              ),
            ),
        ],
      ),
    ),
  );
}
