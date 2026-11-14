import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../core/shift_formatters.dart';
import '../../data/models/shift.dart';
import '../../state/settings_provider.dart';
import '../../state/shift_provider.dart';

class ShiftFormScreen extends StatefulWidget {
  const ShiftFormScreen({super.key, this.shift, this.initialDay});
  final Shift? shift;

  /// New shifts opened from a calendar day start on that day (09:00–10:00).
  final DateTime? initialDay;
  @override
  State<ShiftFormScreen> createState() => _ShiftFormScreenState();
}

class _ShiftFormScreenState extends State<ShiftFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _note;
  late final TextEditingController _tags;
  late final TextEditingController _links;
  late DateTime _start;
  late DateTime _end;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    final day = widget.initialDay;
    final defaultEnd = day == null
        ? DateTime.now()
        : DateTime(day.year, day.month, day.day, 10);
    _end = widget.shift?.end.toLocal() ?? defaultEnd;
    _start = widget.shift?.start.toLocal() ??
        _end.subtract(const Duration(hours: 1));
    _note = TextEditingController(text: widget.shift?.note ?? '');
    _tags = TextEditingController(text: widget.shift?.tags.join(', ') ?? '');
    _links = TextEditingController(text: widget.shift?.links.join('\n') ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    _tags.dispose();
    _links.dispose();
    super.dispose();
  }

  String _earningsLine(Duration worked, SettingsProvider settings) {
    if (worked.isNegative || !_end.isAfter(_start)) {
      return 'Fix the end time to calculate earnings.';
    }
    if (!settings.hasRate) {
      return 'Worked: ${shiftDuration(worked)}. Set an hourly rate to see earnings.';
    }
    final amount =
        Shift.earningsFor(worked.inMilliseconds, settings.hourlyRate);
    final rate = formatMoney(settings.hourlyRate, settings.currencyCode);
    final earned = formatMoney(amount, settings.currencyCode);
    return '${shiftDuration(worked)} × $rate = $earned';
  }

  List<String> _split(String value, Pattern separator) => value
      .split(separator)
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();

  Duration get _pause => widget.shift?.paused ?? Duration.zero;

  Future<void> _pick(bool start) async {
    final old = start ? _start : _end;
    final date = await showDatePicker(
        context: context,
        initialDate: old,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100, 12, 31));
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(old));
    if (time == null || !mounted) return;
    setState(() {
      final chosen =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (start) {
        _start = chosen;
      } else {
        _end = chosen;
      }
      _timeError = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final worked = _end.difference(_start) - _pause;
    if (!_end.isAfter(_start) || worked.isNegative) {
      setState(() => _timeError =
          'End must follow start and allow for the recorded pause.');
      return;
    }
    final shift = Shift(
        id: widget.shift?.id,
        serverId: widget.shift?.serverId,
        start: _start.toUtc(),
        end: _end.toUtc(),
        durationMs: worked.inMilliseconds,
        note: _note.text.trim(),
        tags: _split(_tags.text, ','),
        links: _split(_links.text, RegExp(r'\r?\n')),
        updatedAt: DateTime.now().toUtc());
    final saved = await context.read<ShiftProvider>().save(shift);
    if (!mounted || saved == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift saved on this device.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShiftProvider>();
    final settings = context.watch<SettingsProvider>();
    final busy = store.isSaving || store.isLoading;
    final worked = _end.difference(_start) - _pause;
    final earningsLine = _earningsLine(worked, settings);
    return PopScope(
        canPop: !store.isSaving,
        child: Scaffold(
          appBar: AppBar(
              title: Text(
                  widget.shift == null ? 'Add manual shift' : 'Edit shift')),
          body: Form(
              key: _formKey,
              child: ListView(padding: const EdgeInsets.all(24), children: [
                const Text(
                    'Start and end are required. Select a separate end date for overnight work.'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                    onPressed: busy ? null : () => _pick(true),
                    icon: const Icon(Icons.event),
                    label: Text('Start: ${shiftDateTime(_start)}')),
                OutlinedButton.icon(
                    onPressed: busy ? null : () => _pick(false),
                    icon: const Icon(Icons.event),
                    label: Text('End: ${shiftDateTime(_end)}')),
                if (_timeError != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(_timeError!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                if (_pause > Duration.zero)
                  Text('Recorded pause preserved: ${shiftDuration(_pause)}'),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _tags,
                    enabled: !busy,
                    decoration: const InputDecoration(
                        labelText: 'Client / project tags',
                        hintText: 'Acme, Website',
                        border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _note,
                    enabled: !busy,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _links,
                    enabled: !busy,
                    minLines: 2,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                        labelText: 'Reference links (one per line)',
                        hintText: 'https://github.com/example/project/pull/1',
                        border: OutlineInputBorder()),
                    validator: (value) {
                      final invalid = _split(value ?? '', RegExp(r'\r?\n'))
                          .any((url) => !Shift.isValidReference(url));
                      return invalid
                          ? 'Use a full http/https URL on each line.'
                          : null;
                    }),
                const SizedBox(height: 20),
                Text(earningsLine),
                if (store.errorMessage != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(store.errorMessage!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: 16),
                FilledButton.icon(
                    onPressed: busy ? null : _save,
                    icon: store.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(store.isSaving ? 'Saving...' : 'Save shift')),
              ])),
        ));
  }
}
