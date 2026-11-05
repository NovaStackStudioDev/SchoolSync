import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    final now = DateTime.now();
    final days = List.generate(14, (i) => now.add(Duration(days: i)));
    return Scaffold(
      appBar: BrandAppBar(title: strings.schoolCalendar),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final weekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
          final poya = index == 4;
          final working = !weekend && !poya;
          return ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: CircleAvatar(
              backgroundColor: working
                  ? AppColors.green.withValues(alpha: 0.18)
                  : AppColors.gold.withValues(alpha: 0.35),
              child: Text(
                DateFormat('d').format(day),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenDeep,
                ),
              ),
            ),
            title: Text(DateFormat('EEEE, d MMM').format(day)),
            subtitle: Text(
              working
                  ? strings.workingDay
                  : poya
                      ? strings.poya
                      : strings.weekend,
            ),
            trailing: Icon(
              working ? Icons.check_circle_rounded : Icons.event_busy_rounded,
              color: working ? AppColors.success : AppColors.muted,
            ),
          );
        },
      ),
    );
  }
}
