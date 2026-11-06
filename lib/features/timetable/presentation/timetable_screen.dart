import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';
import '../../../core/widgets/record_form.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key, this.title});
  final String? title;
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _db = SchoolRepository();
  String _day = DateFormat('EEEE', 'en').format(SchoolDatabase.now);
  bool _school = false;
  Future<DbRow> _load() async {
    final principal = await _db.isPrincipal();
    return {
      'principal': principal,
      'slots': await _db.timetable(
        teacher: principal || _school ? null : await _db.requireTeacherId(),
        weekday: _day,
      ),
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BrandAppBar(title: widget.title ?? 'Timetable'),
    body: Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              for (final day in [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(day.substring(0, 3)),
                    selected: _day == day,
                    onSelected: (_) => setState(() => _day = day),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: LiveData<DbRow>(
            key: ValueKey('$_day-$_school'),
            load: _load,
            builder: (context, data) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (data['principal'] != true)
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('My Timetable')),
                      ButtonSegment(
                        value: true,
                        label: Text('School Timetable'),
                      ),
                    ],
                    selected: {_school},
                    onSelectionChanged: (v) =>
                        setState(() => _school = v.first),
                  ),
                const SizedBox(height: 14),
                if ((data['slots'] as List).isEmpty)
                  const NoRecords(
                    message: 'No timetable entries for this day.',
                  ),
                for (final slot in data['slots'])
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.schedule_outlined,
                        color: AppColors.greenDark,
                      ),
                      title: Text(
                        '${_time(slot['periods']?['start_time'])} – ${_time(slot['periods']?['end_time'])}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${slot['school_classes']?['name']} · ${slot['subjects']?['name']}\n${slot['teachers']?['profiles']?['full_name']}',
                      ),
                      onTap: data['principal'] == true
                          ? () => _editSlot(DbRow.from(slot))
                          : null,
                    ),
                  ),
                if (data['principal'] == true) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _editSlot(null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Timetable Entry'),
                  ),
                  TextButton.icon(
                    onPressed: _period,
                    icon: const Icon(Icons.more_time),
                    label: const Text('Manage School Periods'),
                  ),
                  TextButton.icon(
                    onPressed: () => editRecord(
                      context,
                      title: 'Add Subject',
                      fields: const [FieldSpec('name', 'Subject name')],
                      save: (v) => _db.save('subjects', v),
                    ),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Add Subject'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
  String _time(dynamic s) => s == null ? '—' : '$s'.substring(0, 5);
  Future<void> _editSlot(DbRow? slot) async {
    await runAction(context, () async {
      final teachers = await _db.teachers();
      final groups = await _db.classes();
      final subjects = await _db.subjects();
      final periods = await _db.periods();
      if (!mounted) return;
      if (teachers.isEmpty ||
          groups.isEmpty ||
          subjects.isEmpty ||
          periods.isEmpty) {
        throw StateError(
          'Add teachers, classes, subjects and school periods before creating a timetable.',
        );
      }
      await editRecord(
        context,
        title: slot == null ? 'Add Timetable Entry' : 'Edit Timetable Entry',
        fields: [
          FieldSpec(
            'weekday',
            'Weekday',
            initial: slot?['weekday'] ?? _day,
            options: {
              for (final day in [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ])
                day: day,
            },
          ),
          FieldSpec(
            'class_id',
            'Class',
            initial: slot?['class_id'],
            options: {for (final c in groups) c['id']: c['name']},
          ),
          FieldSpec(
            'teacher_id',
            'Teacher',
            initial: slot?['teacher_id'],
            options: {
              for (final t in teachers.where(
                (t) => t['profiles']?['is_active'] == true,
              ))
                t['id']: t['profiles']['full_name'],
            },
          ),
          FieldSpec(
            'subject_id',
            'Subject',
            initial: slot?['subject_id'],
            options: {for (final s in subjects) s['id']: s['name']},
          ),
          FieldSpec(
            'period_id',
            'Period',
            initial: slot?['period_id'],
            options: {
              for (final p in periods)
                p['id']:
                    '${p['period_number']} · ${_time(p['start_time'])} – ${_time(p['end_time'])}',
            },
          ),
        ],
        save: (v) => _db.saveTimetable(v, id: slot?['id']),
      );
    });
  }

  Future<void> _period() async {
    await runAction(context, () async {
      final periods = await _db.periods();
      if (!mounted) return;
      final selected = await showModalBottomSheet<DbRow>(
        context: context,
        builder: (c) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Period'),
                onTap: () => Navigator.pop(c, <String, dynamic>{}),
              ),
              for (final p in periods)
                ListTile(
                  title: Text(
                    'Period ${p['period_number']} · ${_time(p['start_time'])} – ${_time(p['end_time'])}',
                  ),
                  onTap: () => Navigator.pop(c, p),
                ),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      await editRecord(
        context,
        title: 'School Period',
        fields: [
          FieldSpec(
            'period_number',
            'Period number',
            initial: selected['period_number']?.toString(),
            keyboardType: TextInputType.number,
            validate: (s) =>
                (int.tryParse(s) ?? 0) < 1 ? 'Enter a positive number' : null,
          ),
          FieldSpec(
            'start_time',
            'Start (HH:mm)',
            initial: selected['start_time'] == null
                ? null
                : _time(selected['start_time']),
            validate: _validTime,
          ),
          FieldSpec(
            'end_time',
            'End (HH:mm)',
            initial: selected['end_time'] == null
                ? null
                : _time(selected['end_time']),
            validate: _validTime,
          ),
        ],
        save: (v) async {
          if ((v['end_time'] as String).compareTo(v['start_time']) <= 0) {
            throw StateError('End time must follow start time.');
          }
          await _db.save('periods', {
            ...v,
            'period_number': int.parse(v['period_number']),
          }, id: selected['id']);
        },
      );
    });
  }

  String? _validTime(String s) =>
      RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(s)
      ? null
      : 'Use HH:mm (24-hour time)';
}
