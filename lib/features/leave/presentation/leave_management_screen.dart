import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/sample_data.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/models/leave_request.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/status_chip.dart';

class LeaveManagementScreen extends StatelessWidget {
  const LeaveManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    final leaves = SampleData.leaves();
    return Scaffold(
      appBar: BrandAppBar(title: strings.leaveApprovals),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: leaves.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final leave = leaves[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        leave.teacherName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    StatusChip.leave(leave.status, strings),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('d MMM').format(leave.fromDate)} – ${DateFormat('d MMM').format(leave.toDate)} · ${leave.dayCount} day(s)',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(leave.reason),
                if (leave.status == LeaveStatus.pending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: Text(strings.reject),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          child: Text(strings.approve),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
