import 'package:flutter/material.dart';

import '../../../core/data/sample_data.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/status_chip.dart';

class ReplacementsScreen extends StatelessWidget {
  const ReplacementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    return Scaffold(
      appBar: BrandAppBar(title: strings.periodReplacements),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            strings.replacementHelp,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          ...SampleData.replacements.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.swap_horiz_rounded, color: AppColors.greenDeep),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.periodLabel} · ${item.className} · ${item.subject}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        StatusChip(
                          label: item.status == 'Assigned'
                              ? strings.assigned
                              : strings.suggested,
                          color: item.status == 'Assigned'
                              ? AppColors.success
                              : AppColors.goldDeep,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('${strings.absentTeacher}: ${item.absentTeacher}'),
                    Text('${strings.coverTeacher}: ${item.coverTeacher}'),
                    if (item.score != null)
                      Text(
                        '${strings.matchScore} ${item.score}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    if (item.status == 'Suggested') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              child: Text(strings.assignOther),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {},
                              child: Text(strings.accept),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class MyReplacementsScreen extends StatelessWidget {
  const MyReplacementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    final mine = SampleData.replacements
        .where((item) => item.coverTeacher == 'N. Perera')
        .toList();
    return Scaffold(
      appBar: BrandAppBar(title: strings.myCover),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mine.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = mine[index];
          return ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.green.withValues(alpha: 0.16)),
            ),
            leading: const Icon(Icons.groups_rounded, color: AppColors.greenDeep),
            title: Text('${item.className} · ${item.subject}'),
            subtitle: Text('${item.weekday} · ${item.periodLabel}'),
            trailing: StatusChip(
              label: strings.assigned,
              color: AppColors.success,
            ),
          );
        },
      ),
    );
  }
}
