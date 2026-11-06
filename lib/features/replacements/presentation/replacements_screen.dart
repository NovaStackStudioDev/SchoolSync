import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';

class ReplacementsScreen extends StatefulWidget {
  const ReplacementsScreen({super.key});
  @override
  State<ReplacementsScreen> createState() => _ReplacementsScreenState();
}

class _ReplacementsScreenState extends State<ReplacementsScreen> {
  final _db = SchoolRepository();
  DateTime _date = SchoolDatabase.now;
  Future<DbRow> _load() async => {
    'uncovered': await _db.uncovered(_date),
    'assigned': await _db.replacements(date: _date),
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'Automatic Replacement'),
    body: Column(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: Text(DateFormat('EEE, d MMM yyyy').format(_date)),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2020),
              lastDate: SchoolDatabase.now.add(const Duration(days: 365)),
            );
            if (picked != null && mounted) setState(() => _date = picked);
          },
        ),
        Expanded(
          child: LiveData<DbRow>(
            key: ValueKey(SchoolDatabase.date(_date)),
            load: _load,
            builder: (context, data) => ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SectionTitle('Periods Needing Cover'),
                const Text(
                  'Teachers must be marked absent or on approved leave. Suggestions include only present teachers who are free during that period.',
                  style: TextStyle(color: AppColors.muted),
                ),
                if ((data['uncovered'] as List).isEmpty)
                  const NoRecords(
                    message: 'No uncovered periods for this date.',
                  ),
                for (final slot in data['uncovered'])
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.swap_horiz,
                        color: AppColors.warning,
                      ),
                      title: Text(
                        '${slot['school_classes']?['name']} · ${slot['subjects']?['name']}',
                      ),
                      subtitle: Text(
                        '${slot['teachers']?['profiles']?['full_name']} · Period ${slot['periods']?['period_number']}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _CandidatesScreen(
                            slot: DbRow.from(slot),
                            date: _date,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SectionTitle('Assigned Replacements'),
                if ((data['assigned'] as List).isEmpty)
                  const NoRecords(message: 'No replacements assigned.'),
                for (final cover in data['assigned'])
                  _coverCard(DbRow.from(cover)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CandidatesScreen extends StatefulWidget {
  const _CandidatesScreen({required this.slot, required this.date});
  final DbRow slot;
  final DateTime date;
  @override
  State<_CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<_CandidatesScreen> {
  String? _selected;
  bool _saving = false;
  final _db = SchoolRepository();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'Suggested Replacements'),
    body: LiveData<List<DbRow>>(
      load: () => _db.candidates(widget.slot, widget.date),
      builder: (context, candidates) => ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_busy),
              title: Text(
                '${widget.slot['teachers']?['profiles']?['full_name']} is absent',
              ),
              subtitle: Text(
                '${widget.slot['school_classes']?['name']} · ${widget.slot['subjects']?['name']}\n${SchoolDatabase.date(widget.date)} · Period ${widget.slot['periods']?['period_number']}',
              ),
            ),
          ),
          const SectionTitle('Available Teachers'),
          if (candidates.isEmpty)
            const NoRecords(
              message: 'No eligible teachers. Check attendance and period availability.',
            ),
          for (final candidate in candidates)
            Card(
              child: ListTile(
                leading: Icon(
                  _selected == candidate['id']
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.greenDark,
                ),
                title: Text(candidate['profiles']?['full_name'] ?? ''),
                subtitle: Text(candidate['reason']),
                onTap: _saving
                    ? null
                    : () => setState(() => _selected = candidate['id']),
              ),
            ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving || !candidates.any((c) => c['id'] == _selected)
                ? null
                : () async {
                    setState(() => _saving = true);
                    final ok = await runAction(
                      context,
                      () => _db.assignReplacement(
                        widget.slot['id'],
                        _selected!,
                        widget.date,
                      ),
                      success: 'Replacement assigned and teacher notified.',
                    );
                    if (!context.mounted) return;
                    if (ok) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _saving = false);
                    }
                  },
            child: Text(_saving ? 'Assigning…' : 'Assign Replacement'),
          ),
        ],
      ),
    ),
  );
}

class MyReplacementsScreen extends StatelessWidget {
  const MyReplacementsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'My Cover Periods'),
    body: LiveData<List<DbRow>>(
      load: () => SchoolRepository().replacements(mine: true),
      builder: (context, covers) => ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (covers.isEmpty)
            const NoRecords(message: 'No cover periods assigned to you.'),
          ...covers.map(_coverCard),
        ],
      ),
    ),
  );
}

Widget _coverCard(DbRow cover) => Card(
  child: ListTile(
    leading: const Icon(Icons.check_circle_outline, color: AppColors.greenDark),
    title: Text('${cover['replacement_teacher']?['profiles']?['full_name']}'),
    subtitle: Text(
      '${cover['timetables']?['school_classes']?['name']} · ${cover['timetables']?['subjects']?['name']}\n${cover['assignment_date']} · Period ${cover['timetables']?['periods']?['period_number']}',
    ),
  ),
);
