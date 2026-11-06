import 'package:flutter/material.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/l10n/l10n_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';
import '../../../core/widgets/record_form.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});
  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final _db = SchoolRepository();
  String _search = '';
  Future<DbRow> _load() async => {
    'teachers': await _db.teachers(),
    'principal': await _db.isPrincipal(),
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BrandAppBar(title: L10nScope.of(context).strings.teachers),
    body: LiveData<DbRow>(
      load: _load,
      builder: (context, data) {
        final teachers = (data['teachers'] as List)
            .where(
              (t) => '${t['profiles']?['full_name']} ${t['employee_number']}'
                  .toLowerCase()
                  .contains(_search.toLowerCase()),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search teachers…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            if (teachers.isEmpty)
              const NoRecords(
                message: 'No teachers found. Add a teacher or invite staff to register.',
              ),
            for (final teacher in teachers)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.greenDeep,
                    child: Text(
                      ('${teacher['profiles']?['full_name'] ?? '?'}')
                          .characters
                          .first,
                    ),
                  ),
                  title: Text(
                    '${teacher['profiles']?['full_name'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${teacher['employee_number']} · ${(teacher['teacher_subjects'] as List? ?? []).map((s) => s['subjects']?['name']).join(', ')}',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: teacher['profiles']?['is_active'] == true
                          ? const Color(0xFFD8F8C8)
                          : const Color(0xFFEBEDED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      teacher['profiles']?['is_active'] == true
                          ? 'Active'
                          : 'Inactive',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  onTap: data['principal'] != true
                      ? null
                      : () => _edit(teacher),
                ),
              ),
            if (data['principal'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FilledButton.icon(
                  onPressed: () => _edit(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Teacher'),
                ),
              ),
          ],
        );
      },
    ),
  );

  Future<void> _edit(DbRow? teacher) async {
    final currentSubjects = (teacher?['teacher_subjects'] as List? ?? [])
        .map((s) => s['subjects']?['name'])
        .join(', ');
    await editRecord(
      context,
      title: teacher == null ? 'Add Teacher' : 'Edit Teacher',
      button: teacher == null ? 'Create Teacher' : 'Save Changes',
      fields: [
        FieldSpec(
          'full_name',
          'Full name',
          initial: teacher?['profiles']?['full_name'],
        ),
        if (teacher == null)
          FieldSpec(
            'email',
            'Email',
            keyboardType: TextInputType.emailAddress,
            validate: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)
                ? null
                : 'Enter a valid email',
          ),
        if (teacher == null)
          FieldSpec(
            'password',
            'Temporary password',
            obscure: true,
            validate: (v) => v.length < 8 ? 'Use at least 8 characters' : null,
          ),
        FieldSpec(
          'phone',
          'Phone',
          required: false,
          initial: teacher?['phone'],
          keyboardType: TextInputType.phone,
        ),
        FieldSpec(
          'employee_number',
          'Employee number',
          initial: teacher?['employee_number'],
        ),
        FieldSpec(
          'subjects',
          'Subjects (comma separated)',
          initial: currentSubjects,
          required: false,
        ),
        if (teacher != null)
          FieldSpec(
            'is_active',
            'Status',
            initial: teacher['profiles']?['is_active'] == true
                ? 'true'
                : 'false',
            options: const {'true': 'Active', 'false': 'Inactive'},
          ),
      ],
      save: (values) async {
        final names = (values.remove('subjects') as String)
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        if (teacher == null) {
          final response = await _db.client.functions.invoke(
            'manage-teacher',
            body: {...values, 'subjects': names},
          );
          if (response.status >= 400 || response.data?['error'] != null) {
            throw StateError(
              '${response.data?['error'] ?? 'Could not create teacher.'}',
            );
          }
        } else {
          await _db.rpc('update_teacher', {
            'target_teacher': teacher['id'],
            'teacher_values': {
              ...values,
              'is_active': values['is_active'] == 'true',
              'subjects': names,
            },
          });
        }
        SchoolDatabase.changed();
      },
    );
  }
}
