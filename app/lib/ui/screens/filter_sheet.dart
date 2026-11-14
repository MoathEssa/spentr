import 'package:flutter/material.dart';

import '../../core/date_labels.dart';
import '../../core/shift_query.dart';

/// Bottom sheet opened from History: date range, tag and sort order.
///
/// Returns the new filter when the user taps *Apply filters* or *Reset*,
/// and null when the sheet is dismissed (History keeps its current filter).
Future<ShiftFilter?> showFilterSheet(
  BuildContext context, {
  required ShiftFilter current,
  required List<String> availableTags,
}) {
  return showModalBottomSheet<ShiftFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _FilterSheet(current: current, availableTags: availableTags),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.availableTags});

  final ShiftFilter current;
  final List<String> availableTags;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DayRange? _range = widget.current.range;
  late final Set<String> _tags = {...widget.current.tags};
  late ShiftSort _sort = widget.current.sort;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range == null
          ? null
          : DateTimeRange(start: _range!.start, end: _range!.end),
      helpText: 'Shifts that started between',
      saveText: 'Done',
    );
    if (picked != null && mounted) {
      setState(() => _range = DayRange(picked.start, picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter shifts', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Date range', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('filter-date-range'),
                      onPressed: _pickRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(_range == null
                          ? 'Any date'
                          : '${shortDate(_range!.start)} – ${shortDate(_range!.end)}'),
                    ),
                  ),
                  if (_range != null)
                    IconButton(
                      tooltip: 'Clear date range',
                      onPressed: () => setState(() => _range = null),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Client / project', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (widget.availableTags.isEmpty)
                Text('No tags yet. Add tags when you save a shift.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final tag in widget.availableTags)
                      FilterChip(
                        label: Text(tag),
                        selected: _tags.contains(tag),
                        onSelected: (on) => setState(
                            () => on ? _tags.add(tag) : _tags.remove(tag)),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              Text('Sort by', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final sort in ShiftSort.values)
                    ChoiceChip(
                      label: Text(sort.label),
                      selected: _sort == sort,
                      onSelected: (_) => setState(() => _sort = sort),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  ShiftFilter(
                    query: widget.current.query,
                    range: _range,
                    tags: {..._tags},
                    sort: _sort,
                  ),
                ),
                child: const Text('Apply filters'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(
                    context, ShiftFilter(query: widget.current.query)),
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
