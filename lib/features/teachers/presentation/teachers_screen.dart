import 'package:flutter/material.dart';

import '../../../core/constants/school_subjects.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/models/teacher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../data/teacher_repository.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  late Future<List<Teacher>> _teachers;

  @override
  void initState() {
    super.initState();
    _teachers = TeacherRepository().listTeachers();
  }

  @override
  Widget build(BuildContext context) {
    final strings = L10nScope.of(context).strings;
    return Scaffold(
      appBar: BrandAppBar(title: strings.teacherDirectory),
      body: FutureBuilder<List<Teacher>>(
        future: _teachers,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: Text(strings.loadingTeachers));
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              title: strings.teachers,
              message: '${strings.couldNotLoadTeachers}\n${snapshot.error}',
            );
          }
          final teachers = snapshot.data ?? const <Teacher>[];
          if (teachers.isEmpty) {
            return EmptyState(
              icon: Icons.groups_rounded,
              title: strings.teachers,
              message: strings.noTeachers,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              final subjects = teacher.subjects
                  .map((code) => subjectLabel(code, strings.sinhala))
                  .join(', ');
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.gold.withValues(alpha: 0.45),
                      foregroundColor: AppColors.greenDeep,
                      child: Text(
                        teacher.initials,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${teacher.employeeNumber} · $subjects',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: teacher.isActive ? strings.active : strings.inactive,
                      color: teacher.isActive ? AppColors.success : AppColors.muted,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
