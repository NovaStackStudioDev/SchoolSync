import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';
import '../../../core/widgets/record_form.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _db = SchoolRepository();
  DateTime _month = DateTime(SchoolDatabase.now.year, SchoolDatabase.now.month);
  DateTime? _selected;
  Future<DbRow> _load() async => {
    'events': await _db.events(),
    'principal': await _db.isPrincipal(),
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'School Calendar'),
    body: LiveData<DbRow>(
      load: _load,
      builder: (context, data) {
        final events = (data['events'] as List)
            .where(
              (e) => (e['calendar_date'] as String).startsWith(
                DateFormat('yyyy-MM').format(_month),
              ),
            )
            .toList();
        final offset = (_month.weekday - 1) % 7;
        final count = DateTime(_month.year, _month.month + 1, 0).day;
        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _month = DateTime(_month.year, _month.month - 1);
                    _selected = null;
                  }),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_month),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _month = DateTime(_month.year, _month.month + 1);
                    _selected = null;
                  }),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Row(
              children: [
                for (final day in [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ])
                  Expanded(
                    child: Center(
                      child: Text(day, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: offset + count,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox.shrink();
                final day = DateTime(
                  _month.year,
                  _month.month,
                  index - offset + 1,
                );
                final hasEvent = events.any(
                  (e) => e['calendar_date'] == SchoolDatabase.date(day),
                );
                final selected =
                    _selected != null &&
                    SchoolDatabase.date(_selected!) == SchoolDatabase.date(day);
                return InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => setState(() => _selected = day),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.greenDark
                          : hasEvent
                          ? AppColors.cream
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.ink,
                          fontWeight: hasEvent
                              ? FontWeight.w800
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SectionTitle(
              _selected == null
                  ? 'Events & School Days'
                  : DateFormat('EEEE, d MMM').format(_selected!),
            ),
            if (!events.any(
              (e) =>
                  _selected == null ||
                  e['calendar_date'] == SchoolDatabase.date(_selected!),
            ))
              const NoRecords(
                message: 'No school calendar records for this date. Holidays are shown only when configured by your school.',
              ),
            for (final event in events.where(
              (e) =>
                  _selected == null ||
                  e['calendar_date'] == SchoolDatabase.date(_selected!),
            ))
              Card(
                child: ListTile(
                  leading: Icon(
                    event['is_working_day'] == true
                        ? Icons.event_available
                        : Icons.event_busy,
                    color: AppColors.greenDark,
                  ),
                  title: Text(
                    event['description']?.toString().isNotEmpty == true
                        ? event['description']
                        : 'School calendar',
                  ),
                  subtitle: Text(
                    '${event['calendar_date']} · ${event['is_working_day'] == true ? 'Working day' : 'Holiday'}',
                  ),
                  onTap: data['principal'] == true
                      ? () => _edit(DbRow.from(event))
                      : null,
                ),
              ),
            if (data['principal'] == true)
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Event / Configure Day'),
                onPressed: () => _edit(null),
              ),
          ],
        );
      },
    ),
  );
  Future<bool?> _edit(DbRow? event) => editRecord(
    context,
    title: event == null ? 'Add School Event' : 'Edit School Event',
    fields: [
      FieldSpec(
        'calendar_date',
        'Date (YYYY-MM-DD)',
        initial:
            event?['calendar_date'] ??
            SchoolDatabase.date(_selected ?? SchoolDatabase.now),
        validate: (s) =>
            DateTime.tryParse(s) == null ||
                !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) ||
                SchoolDatabase.date(DateTime.parse(s)) != s
            ? 'Enter a valid date'
            : null,
      ),
      FieldSpec(
        'description',
        'Event / description',
        initial: event?['description'],
      ),
      FieldSpec(
        'is_working_day',
        'School day',
        initial: event?['is_working_day'] == false ? 'false' : 'true',
        options: const {'true': 'Working day', 'false': 'Holiday / closed'},
      ),
    ],
    save: (v) => _db.save('school_calendar', {
      ...v,
      'is_working_day': v['is_working_day'] == 'true',
    }, id: event?['id']),
  );
}
