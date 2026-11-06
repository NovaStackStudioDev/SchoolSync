import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/brand_surface.dart';
import '../../../core/widgets/live_data.dart';
import '../../../core/widgets/record_form.dart';
import '../../auth/data/auth_repository.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../classes/presentation/classes_screen.dart';
import '../../leave/presentation/leave_management_screen.dart';
import '../../leave/presentation/leave_request_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../replacements/presentation/replacements_screen.dart';
import '../../timetable/presentation/timetable_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.teacher});
  final bool teacher;
  void _open(BuildContext c, Widget page) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => page));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'Profile & Settings'),
    body: LiveData<DbRow>(
      load: () => SchoolRepository().profile(),
      builder: (context, profile) => ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.greenDeep,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.gold,
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.greenDeep,
                    ),
                  ),
                  title: Text(
                    profile['full_name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  subtitle: Text(
                    teacher ? 'Teacher' : 'Principal',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const BrandWaves(height: 24),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _tile(
            Icons.person_outline,
            'My Profile',
            () => editRecord(
              context,
              title: 'My Profile',
              fields: [
                FieldSpec(
                  'full_name',
                  'Full name',
                  initial: profile['full_name'],
                ),
              ],
              save: (v) => SchoolRepository().rpc('update_my_profile', {
                'new_name': v['full_name'],
              }),
            ),
          ),
          _tile(
            Icons.lock_outline,
            'Change Password',
            () => _password(context),
          ),
          _tile(
            Icons.language,
            'App Language',
            L10nScope.of(context).toggleLanguage,
          ),
          _tile(
            Icons.class_outlined,
            'Classes & Students',
            () => _open(context, const ClassesScreen()),
          ),
          _tile(
            Icons.calendar_view_week_outlined,
            'Timetable',
            () => _open(context, const TimetableScreen()),
          ),
          _tile(
            Icons.event_note_outlined,
            teacher ? 'My Leave Requests' : 'Leave Approvals',
            () => _open(
              context,
              teacher
                  ? const LeaveRequestScreen()
                  : const LeaveManagementScreen(),
            ),
          ),
          _tile(
            Icons.swap_horiz,
            'Teacher Replacements',
            () => _open(
              context,
              teacher
                  ? const MyReplacementsScreen()
                  : const ReplacementsScreen(),
            ),
          ),
          _tile(
            Icons.calendar_month_outlined,
            'School Calendar',
            () => _open(context, const CalendarScreen()),
          ),
          _tile(
            Icons.notifications_outlined,
            'Notifications',
            () => _open(context, const NotificationsScreen()),
          ),
          if (!teacher)
            _tile(Icons.settings_outlined, 'School Settings', () async {
              await runAction(context, () async {
                final db = SchoolRepository();
                final sid = await db.schoolId();
                final school = await db.client
                    .from('schools')
                    .select()
                    .eq('id', sid)
                    .single();
                if (!context.mounted) return;
                await editRecord(
                  context,
                  title: 'School Settings',
                  fields: [
                    FieldSpec(
                      'attendance_cutoff',
                      'Attendance cutoff (HH:mm)',
                      initial: '${school['attendance_cutoff']}'.substring(0, 5),
                      validate: (s) =>
                          RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(s)
                          ? null
                          : 'Enter HH:mm',
                    ),
                  ],
                  save: (v) async {
                    await db.requirePrincipal();
                    await db.client.from('schools').update(v).eq('id', sid);
                    SchoolDatabase.changed();
                  },
                );
              });
            }),
          _tile(
            Icons.help_outline,
            'Help & Support',
            () => showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('SchoolSync Help'),
                content: const Text(
                  'Contact your school principal for account access, class assignments, attendance corrections and timetable changes.\n\nPull down on a list to refresh school data. Tap a record to edit it when your role permits.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
          _tile(
            Icons.info_outline,
            'About SchoolSync',
            () => showAboutDialog(
              context: context,
              applicationName: 'SchoolSync',
              applicationVersion: '1.0.0',
              children: [
                const Text(
                  'Smart School Management\nTeachers · Students · Attendance · Timetables',
                ),
              ],
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'Logout',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () => runAction(context, () async {
                await AuthRepository().logout();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _tile(IconData icon, String title, VoidCallback onTap) => Card(
    child: ListTile(
      leading: Icon(icon, color: AppColors.greenDeep),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    ),
  );
}

Future<bool?> _password(BuildContext context) => editRecord(
  context,
  title: 'Change Password',
  fields: [
    FieldSpec(
      'password',
      'New password',
      obscure: true,
      validate: (s) => s.length < 8 ? 'Use at least 8 characters' : null,
    ),
    const FieldSpec('confirm', 'Confirm password', obscure: true),
  ],
  save: (v) async {
    if (v['password'] != v['confirm']) {
      throw StateError('Passwords do not match.');
    }
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: v['password']),
    );
  },
);

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'Reset Password'),
    body: Center(
      child: FilledButton(
        onPressed: () async {
          final ok = await _password(context);
          if (ok == true) onDone();
        },
        child: const Text('Set New Password'),
      ),
    ),
  );
}
