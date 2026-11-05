import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';

class MarkAttendanceScreen extends StatelessWidget {
  const MarkAttendanceScreen({super.key});

  bool get _beforeCutoff {
    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
      AppConstants.attendanceCutoffHour,
      AppConstants.attendanceCutoffMinute,
    );
    return now.isBefore(cutoff);
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    final open = _beforeCutoff;
    return Scaffold(
      appBar: BrandAppBar(title: strings.markAttendance),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.greenDeep, AppColors.greenDark],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    open ? Icons.fingerprint_rounded : Icons.lock_clock_rounded,
                    color: AppColors.gold,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    open ? strings.checkInOpen : strings.cutoffPassed,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.cutoffHelp,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: open ? () {} : null,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(strings.markMePresent),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.holidayNote,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
