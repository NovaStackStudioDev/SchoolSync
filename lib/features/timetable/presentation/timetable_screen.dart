import 'package:flutter/material.dart';

import '../../../core/data/sample_data.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    final slots = SampleData.teacherTimetable();
    final periods = SampleData.periods;
    return Scaffold(
      appBar: BrandAppBar(title: title ?? strings.myTimetable),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...periods.map((period) {
            final slot = slots.where((s) => s.period.id == period.id).firstOrNull;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: slot?.isCover == true ? AppColors.cream : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: slot == null
                      ? AppColors.green.withValues(alpha: 0.08)
                      : AppColors.green.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          period.label.replaceAll('Period ', 'P'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          period.startTime,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: slot == null
                        ? Text(strings.freePeriod, style: const TextStyle(color: AppColors.muted))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${slot.subject} · ${slot.className}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                slot.isCover ? strings.coverAssignment : slot.teacherName,
                                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                  Icon(
                    slot == null
                        ? Icons.hourglass_empty_rounded
                        : slot.isCover
                            ? Icons.swap_horiz_rounded
                            : Icons.menu_book_rounded,
                    color: slot?.isCover == true ? AppColors.goldDeep : AppColors.greenDark,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
