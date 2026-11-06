import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_surface.dart';
import '../../../core/widgets/live_data.dart';
import '../../../core/widgets/module_card.dart';
import '../../../core/widgets/school_logo.dart';
import '../../attendance/presentation/attendance_overview_screen.dart';
import '../../attendance/presentation/mark_attendance_screen.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../classes/presentation/classes_screen.dart';
import '../../leave/presentation/leave_management_screen.dart';
import '../../leave/presentation/leave_request_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../replacements/presentation/replacements_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../teachers/presentation/teachers_screen.dart';
import '../../timetable/presentation/timetable_screen.dart';

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({super.key, required this.teacher});
  final bool teacher;
  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    final teacher = widget.teacher;
    final pages = <Widget>[
      _Home(teacher: teacher),
      teacher ? const ClassesScreen() : const TeachersScreen(),
      teacher ? const MarkAttendanceScreen() : const ReportsScreen(),
      ProfileScreen(teacher: teacher),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.home,
          ),
          NavigationDestination(
            icon: Icon(teacher ? Icons.class_outlined : Icons.groups_outlined),
            label: teacher ? 'Classes' : strings.teachers,
          ),
          NavigationDestination(
            icon: Icon(teacher ? Icons.fact_check_outlined : Icons.bar_chart),
            label: teacher ? strings.attendance : strings.reports,
          ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.teacher});
  final bool teacher;
  void _open(BuildContext c, Widget screen) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => screen));
  @override
  Widget build(BuildContext context) {
    final s = L10nScope.of(context).strings;
    return Scaffold(
      body: LiveData<DbRow>(
        load: () => SchoolRepository().dashboard(teacher: teacher),
        builder: (context, data) {
          final staff = (data['attendance'] as List).cast<DbRow>();
          final present = staff
              .where((r) => ['present', 'late'].contains(r['status']))
              .length;
          final rate = staff.isEmpty
              ? '—'
              : '${(present / staff.length * 100).round()}%';
          final hour = SchoolDatabase.now.hour;
          final greeting = hour < 12
              ? 'Good Morning,'
              : hour < 17
              ? 'Good Afternoon,'
              : 'Good Evening,';
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.greenDeep, AppColors.greenDark],
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 12, 10),
                      child: Row(
                        children: [
                          const SchoolLogo(size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  teacher
                                      ? data['profile']['full_name']
                                      : 'Principal',
                                  style: const TextStyle(
                                    fontSize: 23,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  DateFormat('EEEE, d MMMM')
                                      .format(SchoolDatabase.now),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: s.notifications,
                            onPressed: () =>
                                _open(context, const NotificationsScreen()),
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Transform.flip(
                      flipY: true,
                      child: const BrandWaves(height: 28),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        StatCard(
                          label: teacher ? 'My Classes' : 'Students',
                          value:
                              '${teacher ? data['classes'] : data['students']}',
                          icon: teacher ? Icons.class_ : Icons.groups,
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          label: teacher ? 'Students' : s.teachers,
                          value:
                              '${teacher ? data['students'] : data['teachers']}',
                          icon: Icons.people_alt_outlined,
                        ),
                      ],
                    ),
                    if (!teacher) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          StatCard(
                            label: 'Classes',
                            value: '${data['classes']}',
                            icon: Icons.class_outlined,
                          ),
                          const SizedBox(width: 12),
                          StatCard(
                            label: s.attendance,
                            value: rate,
                            icon: Icons.calendar_today_outlined,
                          ),
                        ],
                      ),
                    ],
                    if (!teacher) ...[
                      const SectionTitle('Pending Actions'),
                      Card(
                        child: Column(
                          children: [
                            _action(
                              context,
                              Icons.event_note,
                              'Leave Requests',
                              '${data['leaves']} pending',
                              const LeaveManagementScreen(),
                              AppColors.danger,
                            ),
                            const Divider(height: 1, indent: 54),
                            _action(
                              context,
                              Icons.swap_horiz,
                              'Teacher Replacement',
                              '${data['uncovered']} uncovered periods',
                              const ReplacementsScreen(),
                              AppColors.warning,
                            ),
                          ],
                        ),
                      ),
                    ],
                    SectionTitle(
                      teacher ? 'Today’s Classes' : 'School Overview',
                      trailing: teacher
                          ? TextButton(
                              onPressed: () =>
                                  _open(context, const TimetableScreen()),
                              child: const Text('View all'),
                            )
                          : null,
                    ),
                    if (teacher) ...[
                      if ((data['slots'] as List).isEmpty)
                        const NoRecords(
                          message: 'No classes scheduled for today.',
                        ),
                      for (final slot in data['slots'])
                        Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.event_note,
                              color: AppColors.greenDark,
                            ),
                            title: Text('${slot['school_classes']?['name']}'),
                            subtitle: Text('${slot['subjects']?['name']}'),
                            trailing: Text(
                              '${(slot['periods']?['start_time'] as String? ?? '').substring(0, 5)}\n${(slot['periods']?['end_time'] as String? ?? '').substring(0, 5)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => _open(
                              context,
                              StudentsScreen(
                                classId: slot['class_id'],
                                className: slot['school_classes']['name'],
                              ),
                            ),
                          ),
                        ),
                    ],
                    ...[
                      (
                        'Classes & Students',
                        Icons.class_outlined,
                        const ClassesScreen(),
                      ),
                      (
                        s.attendance,
                        Icons.fact_check_outlined,
                        teacher
                            ? const MarkAttendanceScreen()
                            : const AttendanceOverviewScreen(),
                      ),
                      (
                        s.timetable,
                        Icons.calendar_view_week_outlined,
                        const TimetableScreen(),
                      ),
                      (
                        teacher ? s.requestLeave : s.leaveApprovals,
                        Icons.event_available_outlined,
                        teacher
                            ? const LeaveRequestScreen()
                            : const LeaveManagementScreen(),
                      ),
                      (
                        s.replacements,
                        Icons.swap_horiz,
                        teacher
                            ? const MyReplacementsScreen()
                            : const ReplacementsScreen(),
                      ),
                      (
                        s.calendar,
                        Icons.calendar_month_outlined,
                        const CalendarScreen(),
                      ),
                    ].map(
                      (item) => Card(
                        child: ListTile(
                          leading: Icon(item.$2, color: AppColors.greenDark),
                          title: Text(
                            item.$1,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _open(context, item.$3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget page,
    Color color,
  ) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle, style: TextStyle(color: color, fontSize: 12)),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => _open(context, page),
  );
}
