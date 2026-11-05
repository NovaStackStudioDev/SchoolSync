import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/module_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    return Scaffold(
      appBar: BrandAppBar(title: strings.reports),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              StatCard(
                label: strings.attendanceRate,
                value: '94%',
                icon: Icons.trending_up_rounded,
              ),
              const SizedBox(width: 10),
              StatCard(
                label: strings.absences30,
                value: '11',
                icon: Icons.person_off_rounded,
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              StatCard(
                label: strings.leavePending,
                value: '1',
                icon: Icons.pending_actions_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              StatCard(
                label: strings.coverPeriods,
                value: '7',
                icon: Icons.swap_horiz_rounded,
                color: AppColors.goldDeep,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListTile(
            tileColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.greenDeep),
            title: Text(strings.attendanceSummary),
            subtitle: Text(strings.attendanceSummaryHint),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            leading: const Icon(Icons.groups_rounded, color: AppColors.goldDeep),
            title: Text(strings.coverLoad),
            subtitle: Text(strings.coverLoadHint),
          ),
        ],
      ),
    );
  }
}
