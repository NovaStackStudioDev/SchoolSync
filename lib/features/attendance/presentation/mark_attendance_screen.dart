import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});
  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  bool _saving = false;
  final _db = SchoolRepository();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'My Attendance'),
    body: LiveData<DbRow?>(
      load: _db.myAttendance,
      builder: (context, record) => ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.greenDeep, AppColors.greenDark],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.fingerprint, size: 72, color: AppColors.gold),
                const SizedBox(height: 16),
                Text(
                  record == null
                      ? 'Ready for your school day?'
                      : 'Attendance recorded',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(SchoolDatabase.now),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (record != null)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: AppColors.greenDark,
                ),
                title: Text('Status: ${record['status']}'),
                subtitle: record['marked_at'] == null
                    ? null
                    : Text('Saved to your school’s attendance register.'),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: record != null || _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await runAction(
                      context,
                      _db.checkIn,
                      success: 'Your attendance has been saved.',
                    );
                    if (mounted) setState(() => _saving = false);
                  },
            icon: const Icon(Icons.check_circle_outline),
            label: Text(_saving ? 'Saving…' : 'Mark Me Present'),
          ),
          const SizedBox(height: 16),
          const Text(
            'The school’s attendance cutoff determines whether your check-in is present or late. The school server verifies the time and working day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.6),
          ),
        ],
      ),
    ),
  );
}
