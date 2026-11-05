import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/module_card.dart';
import '../../attendance/presentation/attendance_overview_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../leave/presentation/leave_management_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../replacements/presentation/replacements_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../teachers/presentation/teachers_screen.dart';
import '../../timetable/presentation/timetable_screen.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _PrincipalHome(),
      const AttendanceOverviewScreen(),
      const LeaveManagementScreen(),
      const ReplacementsScreen(),
    ];

    final strings = L10nScope.of(context).strings;
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: strings.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.how_to_reg_outlined),
            selectedIcon: const Icon(Icons.how_to_reg_rounded),
            label: strings.attendance,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note_rounded),
            label: strings.leave,
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz_outlined),
            selectedIcon: const Icon(Icons.swap_horiz_rounded),
            label: strings.cover,
          ),
        ],
      ),
    );
  }
}

class _PrincipalHome extends StatelessWidget {
  const _PrincipalHome();

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    return Scaffold(
      appBar: BrandAppBar(
        title: strings.principal,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => AuthRepository().logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        children: [
          GradientHeader(
            title: strings.schoolOps,
            subtitle: strings.schoolName,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                StatCard(
                  label: strings.teachers,
                  value: '42',
                  icon: Icons.groups_rounded,
                ),
                const SizedBox(width: 10),
                StatCard(
                  label: strings.presentToday,
                  value: '38',
                  icon: Icons.verified_rounded,
                ),
                const SizedBox(width: 10),
                StatCard(
                  label: strings.coverNeeded,
                  value: '2',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
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
                  title: strings.teachers,
                  subtitle: strings.directoryHint,
                  icon: Icons.people_alt_rounded,
                  onTap: () => _open(context, const TeachersScreen()),
                ),
                ModuleCard(
                  title: strings.attendance,
                  subtitle: strings.dailyRoll,
                  icon: Icons.fact_check_rounded,
                  accent: AppColors.greenDark,
                  onTap: () => _open(context, const AttendanceOverviewScreen()),
                ),
                ModuleCard(
                  title: strings.leave,
                  subtitle: strings.approveLeave,
                  icon: Icons.event_available_rounded,
                  accent: AppColors.info,
                  onTap: () => _open(context, const LeaveManagementScreen()),
                ),
                ModuleCard(
                  title: strings.replacements,
                  subtitle: strings.rankHint,
                  icon: Icons.swap_horiz_rounded,
                  accent: AppColors.goldDeep,
                  onTap: () => _open(context, const ReplacementsScreen()),
                ),
                ModuleCard(
                  title: strings.calendar,
                  subtitle: strings.calendarHint,
                  icon: Icons.calendar_month_rounded,
                  onTap: () => _open(context, const CalendarScreen()),
                ),
                ModuleCard(
                  title: strings.timetable,
                  subtitle: strings.timetableHint,
                  icon: Icons.view_week_rounded,
                  onTap: () => _open(
                    context,
                    TimetableScreen(title: strings.schoolTimetable),
                  ),
                ),
                ModuleCard(
                  title: strings.reports,
                  subtitle: strings.reportsHint,
                  icon: Icons.bar_chart_rounded,
                  accent: AppColors.greenDeep,
                  onTap: () => _open(context, const ReportsScreen()),
                ),
                ModuleCard(
                  title: strings.alerts,
                  subtitle: strings.alertsHint,
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
