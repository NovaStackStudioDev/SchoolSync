import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/data/sample_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/module_card.dart';
import '../../../core/widgets/status_chip.dart';

class AttendanceOverviewScreen extends StatelessWidget {
  const AttendanceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    final records = SampleData.attendanceToday();
    final present = records.where((r) => r.status.name == 'present').length;
    return Scaffold(
      appBar: BrandAppBar(title: strings.dailyAttendance),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Cutoff ${AppConstants.cutoffLabel} · ${AppConstants.timezone}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatCard(
                label: strings.present,
                value: '$present',
                icon: Icons.how_to_reg_rounded,
              ),
              const SizedBox(width: 10),
              StatCard(
                label: strings.onLeave,
                value: '1',
                icon: Icons.event_busy_rounded,
                color: AppColors.info,
              ),
              const SizedBox(width: 10),
              StatCard(
                label: strings.pending,
                value: '1',
                icon: Icons.hourglass_empty_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...records.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: AppColors.greenDeep),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.teacherName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            record.markedAt == null
                                ? strings.notMarked
                                : '${strings.markedAt} ${DateFormat.jm().format(record.markedAt!)}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    StatusChip.attendance(record.status, strings),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
