import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/data/school_database.dart';
import '../../../core/data/school_repository.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/live_data.dart';
import '../../../core/widgets/record_form.dart';

class TimetableUploadsScreen extends StatelessWidget {
  const TimetableUploadsScreen({super.key});
  Future<DbRow> _load() async {
    final db = SchoolRepository();
    return {
      'principal': await db.isPrincipal(),
      'files': await db.timetableUploads(),
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const BrandAppBar(title: 'Timetable Photos / PDFs'),
    body: LiveData<DbRow>(
      load: _load,
      builder: (context, data) => ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            'Keep the original timetable file and confirm its periods. Only published periods are used to find free teachers.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TimetableDocumentScreen(
                  principal: data['principal'] == true,
                ),
              ),
            ),
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Photo / PDF'),
          ),
          if ((data['files'] as List).isEmpty)
            const NoRecords(message: 'No timetable files uploaded yet.'),
          for (final file in (data['files'] as List).reversed)
            Card(
              child: ListTile(
                leading: Icon(
                  file['mime_type'] == 'application/pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                ),
                title: Text(file['file_name']),
                subtitle: Text(
                  '${file['teachers']?['profiles']?['full_name']} · ${file['status'] == 'draft' && file['submitted_at'] != null ? 'Awaiting principal review' : file['status']}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TimetableDocumentScreen(
                      upload: DbRow.from(file),
                      principal: data['principal'] == true,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class TimetableDocumentScreen extends StatefulWidget {
  const TimetableDocumentScreen({
    super.key,
    this.upload,
    required this.principal,
  });
  final DbRow? upload;
  final bool principal;
  @override
  State<TimetableDocumentScreen> createState() =>
      _TimetableDocumentScreenState();
}

class _TimetableDocumentScreenState extends State<TimetableDocumentScreen> {
  final _db = SchoolRepository();
  DbRow? _upload;
  Uint8List? _bytes;
  String? _fileName;
  String? _mime;
  String? _teacher;
  DateTime _from = SchoolDatabase.now;
  bool _dateOnly = true;
  bool _busy = false;
  bool _dirty = false;
  bool get _editable =>
      widget.principal || _upload == null || _upload!['status'] != 'published';
  final _entries = <DbRow>[];
  late final Future<DbRow> _options;
  @override
  void initState() {
    super.initState();
    _upload = widget.upload;
    _teacher = _upload?['teacher_id'];
    _fileName = _upload?['file_name'];
    _mime = _upload?['mime_type'];
    _options = _load();
  }

  Future<DbRow> _load() async {
    if (_upload != null) _bytes = await _db.timetableFile(_upload!);
    if (!widget.principal) _teacher = await _db.requireTeacherId();
    if (_upload?['effective_date'] != null) {
      _from = DateTime.parse(_upload!['effective_date']);
    }
    if (_upload != null) {
      _dateOnly = _upload!['effective_date'] == null || _upload!['date_only'] == true;
      _entries.addAll(
        (_upload!['proposed_entries'] as List? ?? []).map(
          (e) => DbRow.from(e as Map),
        ),
      );
    }
    return {
      'teachers': await _db.teachers(),
      'classes': await _db.classes(),
      'subjects': await _db.subjects(),
      'periods': await _db.periods(),
    };
  }

  Future<void> _pick() async {
    await runAction(context, () async {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Timetable Photo or PDF',
            extensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
            mimeTypes: [
              'application/pdf',
              'image/png',
              'image/jpeg',
              'image/webp',
            ],
            uniformTypeIdentifiers: [
              'com.adobe.pdf',
              'public.png',
              'public.jpeg',
              'org.webmproject.webp',
            ],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 10 * 1024 * 1024) {
        throw StateError('Choose a file smaller than 10 MB.');
      }
      final bytes = await file.readAsBytes();
      final extension = file.name.split('.').last.toLowerCase();
      final mime = switch (extension) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'webp' => 'image/webp',
        _ => throw StateError('Choose a Photo/PDF file.'),
      };
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _fileName = file.name;
        _mime = mime;
        _upload = null;
        _dirty = true;
      });
    });
  }

  Future<void> _current() async {
    if (_teacher == null) return;
    setState(() => _busy = true);
    await runAction(context, () async {
      final slots = await _db.timetable(
        teacher: _teacher,
        date: _from,
        weekday: _dateOnly ? _weekday(_from) : null,
      );
      if (mounted) {
        setState(() {
          _entries.clear();
          _entries.addAll(
            slots.map(
              (s) => {
                'weekday': s['weekday'],
                'class_id': s['class_id'],
                'subject_id': s['subject_id'],
                'period_id': s['period_id'],
              },
            ),
          );
          _dirty = true;
        });
      }
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save(bool publish) async {
    if (_teacher == null || _bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a teacher and a Photo/PDF first.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () async {
        _upload ??= await _db.uploadTimetableFile(
          _teacher!,
          _fileName!,
          _mime!,
          _bytes!,
        );
        if (publish) {
          if (widget.principal) {
            await _db.publishTimetable(_upload!, _entries, _from, _dateOnly);
          } else {
            await _db.submitTimetable(_upload!, _entries, _from, _dateOnly);
          }
        }
      },
      success: publish
          ? (widget.principal
                ? 'Timetable published. Free-period availability has been updated.'
                : 'Timetable sent to the principal for review. Your active timetable stays unchanged until published.')
          : 'File saved as a draft. Confirm periods before publishing.',
    );
    if (mounted) {
      setState(() {
        _busy = false;
        if (ok) {
          _dirty = !publish && _entries.isNotEmpty;
          if (publish && widget.principal) _upload!['status'] = 'published';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty && !_busy,
    onPopInvokedWithResult: (popped, _) async {
      if (popped || _busy) return;
      final leave = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Leave without publishing changes?'),
          content: const Text(
            'Saved source files remain in Timetable Photos / PDFs. Unsaved period edits will be discarded.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (leave == true && mounted) {
        setState(() => _dirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    },
    child: Scaffold(
      appBar: const BrandAppBar(title: 'Timetable Document'),
      body: FutureBuilder<DbRow>(
        future: _options,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load timetable document: ${snapshot.error}',
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final options = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...[
                DropdownButtonFormField<String>(
                  initialValue: _teacher,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Teacher'),
                  items: [
                    for (final t in options['teachers'])
                      if (t['profiles']?['is_active'] == true || t['id'] == _teacher)
                        DropdownMenuItem(
                          value: t['id'] as String,
                          child: Text(
                            '${t['profiles']['full_name']} · ${t['employee_number']}',
                          ),
                        ),
                  ],
                  onChanged: !widget.principal || _busy || _upload != null
                      ? null
                      : (v) => setState(() {
                          _teacher = v;
                          _entries.clear();
                          _dirty = true;
                        }),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _bytes == null
                        ? 'Choose Photo / PDF'
                        : 'Choose Revised Photo / PDF',
                  ),
                ),
              ],
              if (_bytes != null) ...[
                SectionTitle(_fileName ?? 'Timetable'),
                SizedBox(
                  height: 340,
                  child: _mime == 'application/pdf'
                      ? PdfViewer.data(
                          _bytes!,
                          sourceName: '${_fileName}_${_bytes.hashCode}',
                          key: ValueKey(_bytes),
                        )
                      : InteractiveViewer(
                          minScale: .5,
                          maxScale: 5,
                          child: Image.memory(
                            _bytes!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, error, _) => const Center(
                              child: Text(
                                'This photo could not be opened. Choose another file.',
                              ),
                            ),
                          ),
                        ),
                ),
              ],
              if (_editable) ...[
                const SectionTitle('Confirm Timetable Periods'),
                const Text(
                  'Read the Photo/PDF and enter or correct the periods below. The image is a reference; automatic assignments use the confirmed, published periods.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _from,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null && mounted) {
                            setState(() {
                              _from = picked;
                              _dirty = true;
                            });
                          }
                        },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Effective date: ${SchoolDatabase.date(_from)}'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('This date only'),
                  subtitle: Text(
                    _dateOnly
                        ? 'Changes apply only to ${SchoolDatabase.date(_from)}.'
                        : 'Replace the teacher’s weekly timetable from this date. Previous dates stay unchanged.',
                  ),
                  value: _dateOnly,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                          _dateOnly = v;
                          _dirty = true;
                        }),
                ),
                TextButton.icon(
                  onPressed: _busy || _teacher == null || _entries.isNotEmpty
                      ? null
                      : _current,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Start From Current Timetable'),
                ),
                for (var index = 0; index < _entries.length; index++)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${_entries[index]['weekday']} · ${_label(options['classes'], _entries[index]['class_id'], 'name')}',
                      ),
                      subtitle: Text(
                        '${_label(options['subjects'], _entries[index]['subject_id'], 'name')} · Period ${_label(options['periods'], _entries[index]['period_id'], 'period_number')}',
                      ),
                      onTap: _busy ? null : () => _editPeriod(options, index),
                      trailing: IconButton(
                        tooltip: 'Remove draft period',
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _entries.removeAt(index);
                                _dirty = true;
                              }),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                TextButton.icon(
                  onPressed: _busy ? null : () => _editPeriod(options, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Period From Document'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy || _bytes == null || _teacher == null
                      ? null
                      : () => _save(false),
                  child: const Text('Save Source File'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy || _entries.isEmpty
                      ? null
                      : () => _save(true),
                  child: Text(
                    _busy
                        ? 'Saving…'
                        : widget.principal
                        ? 'Publish ${_entries.length} Confirmed Periods'
                        : 'Submit ${_entries.length} Periods for Review',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
  String _weekday(DateTime date) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][date.weekday - 1];
  String _label(dynamic rows, dynamic id, String field) =>
      (rows as List)
          .where((r) => r['id'] == id)
          .map((r) => '${r[field]}')
          .firstOrNull ??
      'Unavailable';
  Future<void> _editPeriod(DbRow options, int? index) async {
    if ((options['classes'] as List).isEmpty ||
        (options['subjects'] as List).isEmpty ||
        (options['periods'] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add school classes, subjects and periods first in Timetable.',
          ),
        ),
      );
      return;
    }
    final current = index == null ? null : _entries[index];
    await editRecord(
      context,
      title: 'Confirm Period',
      fields: [
        FieldSpec(
          'weekday',
          'Weekday',
          initial: current?['weekday'] ?? _weekday(_from),
          options: _dateOnly
              ? {_weekday(_from): _weekday(_from)}
              : {
                  for (final d in [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday',
                  ])
                    d: d,
                },
        ),
        FieldSpec(
          'class_id',
          'Class',
          initial: current?['class_id'],
          options: {for (final c in options['classes']) c['id']: c['name']},
        ),
        FieldSpec(
          'subject_id',
          'Subject',
          initial: current?['subject_id'],
          options: {for (final s in options['subjects']) s['id']: s['name']},
        ),
        FieldSpec(
          'period_id',
          'Period',
          initial: current?['period_id'],
          options: {
            for (final p in options['periods'])
              p['id']:
                  'Period ${p['period_number']} · ${p['start_time']}–${p['end_time']}',
          },
        ),
      ],
      save: (v) async {
        setState(() {
          if (index == null) {
            _entries.add(v);
          } else {
            _entries[index] = v;
          }
          _dirty = true;
        });
      },
    );
  }
}
