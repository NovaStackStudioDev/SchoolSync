import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';
import '../../../core/widgets/record_form.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});
  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _db = SchoolRepository();
  String _search = '';
  Future<DbRow> _load() async {
    final principal = await _db.isPrincipal();
    final groups = await _db.classes();
    if (principal) return {'principal': true, 'classes': groups};
    final ids = (await _db.timetable(teacher: await _db.requireTeacherId()))
        .map((s) => s['class_id'])
        .toSet();
    return {
      'principal': false,
      'classes': groups.where((c) => ids.contains(c['id'])).toList(),
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'Classes'),
    body: LiveData<DbRow>(
      load: _load,
      builder: (context, data) {
        final groups = (data['classes'] as List)
            .where(
              (c) =>
                  '${c['name']}'.toLowerCase().contains(_search.toLowerCase()),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search classes…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (s) => setState(() => _search = s),
            ),
            const SizedBox(height: 16),
            if (groups.isEmpty)
              const NoRecords(
                message: 'No classes found. Add your school’s classes to get started.',
              ),
            for (final group in groups)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.class_outlined,
                    color: AppColors.greenDark,
                  ),
                  title: Text(
                    group['name'],
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${(group['students'] as List).where((s) => s['is_active'] == true).length} Students',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentsScreen(
                        classId: group['id'],
                        className: group['name'],
                      ),
                    ),
                  ),
                  onLongPress: data['principal'] != true
                      ? null
                      : () => _edit(group),
                ),
              ),
            if (data['principal'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FilledButton.icon(
                  onPressed: () => _edit(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Class'),
                ),
              ),
          ],
        );
      },
    ),
  );
  Future<bool?> _edit(DbRow? group) => editRecord(
    context,
    title: group == null ? 'Add Class' : 'Edit Class',
    fields: [FieldSpec('name', 'Class name', initial: group?['name'])],
    save: (v) => _db.save('school_classes', v, id: group?['id']),
  );
}

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({
    super.key,
    required this.classId,
    required this.className,
  });
  final String classId;
  final String className;
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _db = SchoolRepository();
  String _search = '';
  Future<DbRow> _load() async => {
    'students': await _db.students(widget.classId),
    'principal': await _db.isPrincipal(),
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BrandAppBar(title: widget.className),
    body: LiveData<DbRow>(
      load: _load,
      builder: (context, data) {
        final pupils = (data['students'] as List)
            .where(
              (s) => '${s['full_name']} ${s['admission_number']}'
                  .toLowerCase()
                  .contains(_search.toLowerCase()),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search students…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentAttendanceScreen(
                    classId: widget.classId,
                    className: widget.className,
                  ),
                ),
              ),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Take Attendance'),
            ),
            const SizedBox(height: 16),
            if (pupils.isEmpty)
              const NoRecords(message: 'No students found in this class.'),
            for (final pupil in pupils)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.cream,
                    child: Text(
                      (pupil['full_name'] as String).characters.first
                          .toUpperCase(),
                    ),
                  ),
                  title: Text(
                    pupil['full_name'],
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(pupil['admission_number']),
                  trailing: Text(
                    pupil['is_active'] == true ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: pupil['is_active'] == true
                          ? AppColors.greenDark
                          : AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  onTap: data['principal'] != true ? null : () => _edit(pupil),
                ),
              ),
            if (data['principal'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton.icon(
                  onPressed: () => _edit(null),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Add Student'),
                ),
              ),
          ],
        );
      },
    ),
  );
  Future<bool?> _edit(DbRow? student) => editRecord(
    context,
    title: student == null ? 'Add Student' : 'Edit Student',
    fields: [
      FieldSpec('full_name', 'Full name', initial: student?['full_name']),
      FieldSpec(
        'admission_number',
        'Admission number',
        initial: student?['admission_number'],
      ),
      FieldSpec(
        'is_active',
        'Status',
        initial: student?['is_active'] == false ? 'false' : 'true',
        options: const {'true': 'Active', 'false': 'Inactive'},
      ),
    ],
    save: (v) => _db.save('students', {
      ...v,
      'class_id': widget.classId,
      'is_active': v['is_active'] == 'true',
    }, id: student?['id']),
  );
}

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
  });
  final String classId;
  final String className;
  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final _db = SchoolRepository();
  DateTime _date = SchoolDatabase.now;
  final _marks = <String, String>{};
  bool _saving = false;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _marks.isEmpty,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop || _saving) return;
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Discard unsaved attendance?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard == true && context.mounted) {
        setState(_marks.clear);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.pop(context);
        });
      }
    },
    child: Scaffold(
      appBar: BrandAppBar(title: 'Attendance · ${widget.className}'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_marks.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Save the current attendance before changing date.',
                            ),
                          ),
                        );
                        return;
                      }
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: SchoolDatabase.now,
                      );
                      if (picked != null && mounted) {
                        setState(() => _date = picked);
                      }
                    },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(DateFormat('EEE, d MMM yyyy').format(_date)),
            ),
          ),
          Expanded(
            child: LiveData<List<DbRow>>(
              key: ValueKey(SchoolDatabase.date(_date)),
              load: () => _db.studentAttendance(widget.classId, _date),
              builder: (context, pupils) => ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Wrap(
                    spacing: 12,
                    children: [
                      for (final status in ['present', 'absent', 'late'])
                        Chip(
                          label: Text(
                            '${status[0].toUpperCase()}${status.substring(1)} ${pupils.where((s) => (_marks[s['id']] ?? s['status']) == status).length}',
                          ),
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: _saving || pupils.isEmpty
                        ? null
                        : () => setState(() {
                            for (final s in pupils) {
                              _marks[s['id']] = 'present';
                            }
                          }),
                    child: const Text('Mark all present'),
                  ),
                  if (pupils.isEmpty)
                    const NoRecords(
                      message: 'Add students to this class before taking attendance.',
                    ),
                  for (final pupil in pupils)
                    Card(
                      child: ListTile(
                        title: Text(pupil['full_name']),
                        subtitle: Text(pupil['admission_number']),
                        trailing: DropdownButton<String>(
                          value: _marks[pupil['id']] ?? pupil['status'],
                          underline: const SizedBox.shrink(),
                          items: ['unmarked', 'present', 'absent', 'late']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (v) => setState(() {
                                  if (v == 'unmarked') {
                                    _marks.remove(pupil['id']);
                                  } else {
                                    _marks[pupil['id']] = v!;
                                  }
                                }),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving || _marks.isEmpty
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          final ok = await runAction(
                            context,
                            () => _db.saveStudentAttendance(
                              widget.classId,
                              _date,
                              _marks,
                            ),
                            success: 'Attendance saved.',
                          );
                          if (mounted) {
                            setState(() {
                              _saving = false;
                              if (ok) _marks.clear();
                            });
                          }
                        },
                  child: Text(_saving ? 'Saving…' : 'Save Attendance'),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
