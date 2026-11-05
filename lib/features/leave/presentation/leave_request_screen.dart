import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/sample_data.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/status_chip.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _reason = TextEditingController();
  DateTimeRange? _range;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    final mine = SampleData.leaves().where((l) => l.teacherId == 't1').toList();
    return Scaffold(
      appBar: BrandAppBar(title: strings.requestLeave),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            strings.leaveHelp,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 180)),
              );
              if (picked != null) setState(() => _range = picked);
            },
            icon: const Icon(Icons.date_range_rounded),
            label: Text(
              _range == null
                  ? strings.chooseDates
                  : '${DateFormat('d MMM').format(_range!.start)} – ${DateFormat('d MMM').format(_range!.end)}',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: strings.reason,
              prefixIcon: const Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.send_rounded),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(strings.submitRequest),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            strings.leaveHistory,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...mine.map(
            (leave) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(leave.reason),
              subtitle: Text(
                '${DateFormat('d MMM').format(leave.fromDate)} · ${leave.dayCount} day(s)',
              ),
              trailing: StatusChip.leave(leave.status, strings),
            ),
          ),
        ],
      ),
    );
  }
}
