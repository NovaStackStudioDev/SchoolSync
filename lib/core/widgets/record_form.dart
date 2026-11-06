import 'package:flutter/material.dart';

import '../data/school_database.dart';
import 'live_data.dart';

class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.options,
    this.required = true,
    this.obscure = false,
    this.initial,
    this.validate,
    this.keyboardType,
  });
  final String key;
  final String label;
  final Map<String, String>? options;
  final bool required;
  final bool obscure;
  final String? initial;
  final String? Function(String)? validate;
  final TextInputType? keyboardType;
}

Future<bool?> editRecord(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  required Future<void> Function(DbRow) save,
  String button = 'Save',
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      _RecordForm(title: title, fields: fields, save: save, button: button),
);

class _RecordForm extends StatefulWidget {
  const _RecordForm({
    required this.title,
    required this.fields,
    required this.save,
    required this.button,
  });
  final String title;
  final List<FieldSpec> fields;
  final Future<void> Function(DbRow) save;
  final String button;
  @override
  State<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<_RecordForm> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _selected = <String, String>{};
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      _controllers[field.key] = TextEditingController(text: field.initial);
      if (field.options != null &&
          field.initial != null &&
          field.options!.containsKey(field.initial)) {
        _selected[field.key] = field.initial!;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final values = <String, dynamic>{
      for (final f in widget.fields)
        f.key: f.options == null
            ? _controllers[f.key]!.text.trim()
            : _selected[f.key],
    };
    final ok = await runAction(context, () => widget.save(values));
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (final field in widget.fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: field.options == null
                        ? TextFormField(
                            controller: _controllers[field.key],
                            obscureText: field.obscure,
                            enabled: !_saving,
                            keyboardType: field.keyboardType,
                            decoration: InputDecoration(
                              labelText:
                                  '${field.label}${field.required ? ' *' : ''}',
                            ),
                            validator: (v) =>
                                field.required && (v ?? '').trim().isEmpty
                                ? 'Required'
                                : field.validate?.call((v ?? '').trim()),
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: _selected[field.key],
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText:
                                  '${field.label}${field.required ? ' *' : ''}',
                            ),
                            items: field.options!.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(
                                      e.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (v) => _selected[field.key] = v!,
                            validator: (v) => field.required && v == null
                                ? 'Select an option'
                                : null,
                          ),
                  ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.button),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
