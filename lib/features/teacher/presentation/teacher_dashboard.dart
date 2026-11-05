import 'package:flutter/material.dart';

import '../../../core/constants/school_subjects.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/models/profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/module_card.dart';
import '../../attendance/presentation/mark_attendance_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../leave/presentation/leave_request_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../replacements/presentation/replacements_screen.dart';
import '../../teachers/data/teacher_repository.dart';
import '../../timetable/presentation/timetable_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key, this.profile});

  final Profile? profile;

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    final pages = [
      _TeacherHome(profile: widget.profile),
      const MarkAttendanceScreen(),
      const LeaveRequestScreen(),
      TimetableScreen(title: strings.myTimetable),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: strings.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.fingerprint_outlined),
            selectedIcon: const Icon(Icons.fingerprint_rounded),
            label: strings.checkIn,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note_rounded),
            label: strings.leave,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_view_week_outlined),
            selectedIcon: const Icon(Icons.calendar_view_week_rounded),
            label: strings.timetable,
          ),
        ],
      ),
    );
  }
}

class _TeacherHome extends StatelessWidget {
  const _TeacherHome({this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    return Scaffold(
      appBar: BrandAppBar(
        title: profile?.fullName ?? strings.teacher,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: () => AuthRepository().logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        children: [
          GradientHeader(
            title: strings.goodMorning,
            subtitle: strings.markBefore,
          ),
          if (profile != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: FutureBuilder<List<String>>(
                future: TeacherRepository().subjectsForCurrentUser(),
                builder: (context, snapshot) {
                  final codes = snapshot.data ?? const <String>[];
                  final labels = codes
                      .map((code) => subjectLabel(code, strings.sinhala))
                      .join(', ');
                  return Text(
                    labels.isEmpty
                        ? strings.mySubjects
                        : '${strings.mySubjects}: $labels',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                StatCard(
                  label: strings.todayStatus,
                  value: strings.open,
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(width: 10),
                StatCard(
                  label: strings.coverPeriods,
                  value: '1',
                  icon: Icons.swap_horiz_rounded,
                  color: AppColors.goldDeep,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                ModuleCard(
                  title: strings.markAttendance,
                  subtitle: strings.beforeCutoff,
                  icon: Icons.fingerprint_rounded,
                  onTap: () => _open(context, const MarkAttendanceScreen()),
                ),
                ModuleCard(
                  title: strings.myTimetable,
                  subtitle: strings.classesAndFree,
                  icon: Icons.menu_book_rounded,
                  onTap: () => _open(context, const TimetableScreen()),
                ),
                ModuleCard(
                  title: strings.requestLeave,
                  subtitle: strings.sendForReview,
                  icon: Icons.event_available_rounded,
                  accent: AppColors.info,
                  onTap: () => _open(context, const LeaveRequestScreen()),
                ),
                ModuleCard(
                  title: strings.coverPeriods,
                  subtitle: strings.assignedCover,
                  icon: Icons.groups_rounded,
                  accent: AppColors.goldDeep,
                  onTap: () => _open(context, const MyReplacementsScreen()),
                ),
                ModuleCard(
                  title: strings.notifications,
                  subtitle: strings.leaveAlerts,
                  icon: Icons.campaign_rounded,
                  onTap: () => _open(context, const NotificationsScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
