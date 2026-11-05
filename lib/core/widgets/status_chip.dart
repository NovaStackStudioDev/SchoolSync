import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/attendance.dart';
import '../models/leave_request.dart';
import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  factory StatusChip.attendance(AttendanceStatus status, AppStrings strings) {
    switch (status) {
      case AttendanceStatus.present:
        return StatusChip(label: strings.present, color: AppColors.success);
      case AttendanceStatus.absent:
        return StatusChip(label: strings.absent, color: AppColors.danger);
      case AttendanceStatus.late:
        return StatusChip(label: strings.late, color: AppColors.warning);
      case AttendanceStatus.leave:
        return StatusChip(label: strings.onLeave, color: AppColors.info);
      case AttendanceStatus.pending:
        return StatusChip(label: strings.pending, color: AppColors.muted);
    }
  }

  factory StatusChip.leave(LeaveStatus status, AppStrings strings) {
    switch (status) {
      case LeaveStatus.pending:
        return StatusChip(label: strings.pending, color: AppColors.warning);
      case LeaveStatus.approved:
        return StatusChip(label: strings.approved, color: AppColors.success);
      case LeaveStatus.rejected:
        return StatusChip(label: strings.rejected, color: AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
