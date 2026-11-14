import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_labels.dart';
import '../../core/money.dart';
import '../../core/routes.dart';
import '../../core/shift_formatters.dart';
import '../../core/shift_query.dart';
import '../../data/models/shift.dart';
import '../../state/settings_provider.dart';
import '../../state/shift_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/shift_tile.dart';
import 'filter_sheet.dart';

/// History tab (E5): every saved shift with note search, date-range and tag
/// filters, and sorting by date, duration or earnings.
///
/// The shift list is shared state from [ShiftProvider]. The search text and
/// filter are owned by this screen with `setState`, as planned in Phase 2,
/// and survive tab switches because [RootShell] keeps tabs in an IndexedStack.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _search = TextEditingController();
  ShiftFilter _filter = const ShiftFilter();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setQuery(String value) =>
      setState(() => _filter = _filter.copyWith(query: value));

  void _clearAll() {
    _search.clear();
    setState(() => _filter = ShiftFilter(sort: _filter.sort));
  }

  Future<void> _openFilters(List<String> tags) async {
    // Otherwise focus returns to the search bar and reopens the keyboard.
    FocusManager.instance.primaryFocus?.unfocus();
    final chosen =
        await showFilterSheet(context, current: _filter, availableTags: tags);
    if (chosen != null && mounted) setState(() => _filter = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShiftProvider>();
    final settings = context.watch<SettingsProvider>();
    final tags = allTags(store.shifts);
    final results =
        _filter.apply(store.shifts, hourlyRate: settings.hourlyRate);
    final busy = store.isLoading || store.isSaving;

    return Scaffold(
      appBar: AppBar(title: const Text('Shift history'), actions: [
        IconButton(
          tooltip: 'Filter shifts',
          onPressed: () => _openFilters(tags),
          icon: Badge(
            isLabelVisible: _filter.activeFilterCount > 0,
            label: Text('${_filter.activeFilterCount}'),
            child: const Icon(Icons.filter_list),
          ),
        ),
        IconButton(
            tooltip: 'Reload shifts',
            onPressed: busy ? null : store.load,
            icon: const Icon(Icons.refresh)),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SearchBar(
            key: const Key('history-search'),
            controller: _search,
            hintText: 'Search notes',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: _setQuery,
            trailing: [
              if (_filter.query.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _search.clear();
                    _setQuery('');
                  },
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ),
        _ActiveFilters(
          filter: _filter,
          onChanged: (next) => setState(() => _filter = next),
          onOpenSheet: () => _openFilters(tags),
        ),
        if (store.isLoading && store.shifts.isNotEmpty)
          const LinearProgressIndicator(),
        if (store.errorMessage != null && store.shifts.isNotEmpty)
          _ErrorRow(
              message: store.errorMessage!, onRetry: busy ? null : store.load),
        Expanded(child: _body(store, settings, results)),
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: busy
              ? null
              : () => Navigator.pushNamed(context, AppRoutes.shiftForm),
          icon: const Icon(Icons.add),
          label: const Text('Add manual shift')),
    );
  }

  Widget _body(
      ShiftProvider store, SettingsProvider settings, List<Shift> results) {
    if (store.shifts.isEmpty) {
      if (store.isLoading) {
        return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading saved shifts...'),
          ]),
        );
      }
      if (store.hasLoadError) {
        return Center(
          child: EmptyState(
            icon: Icons.error_outline,
            isError: true,
            title: 'Saved shifts are unavailable.',
            message: store.errorMessage,
            actionLabel: 'Retry',
            onAction: store.load,
          ),
        );
      }
      return const Center(
        child: EmptyState(
          icon: Icons.history,
          title: 'No shifts yet. Add your first shift.',
          message: 'Shifts you save will appear here, newest first.',
        ),
      );
    }
    if (results.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.search_off,
          title: 'No shifts match',
          message: 'Try a different search, date range or tag.',
          actionLabel: 'Clear search & filters',
          onAction: _clearAll,
        ),
      );
    }

    final byDate =
        _filter.sort == ShiftSort.newest || _filter.sort == ShiftSort.oldest;
    final rows = <Widget>[
      _ResultsSummary(results: results, settings: settings),
    ];
    String? currentMonth;
    for (final shift in results) {
      final month = monthLabel(shift.start.toLocal());
      if (byDate && month != currentMonth) {
        currentMonth = month;
        rows.add(_MonthHeader(month));
      }
      rows.add(ShiftTile(shift: shift, settings: settings));
    }

    return RefreshIndicator(
      onRefresh: store.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: rows,
      ),
    );
  }
}

/// Removable chips for the date range, tags and a non-default sort order.
class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.filter,
    required this.onChanged,
    required this.onOpenSheet,
  });

  final ShiftFilter filter;
  final ValueChanged<ShiftFilter> onChanged;
  final VoidCallback onOpenSheet;

  @override
  Widget build(BuildContext context) {
    final range = filter.range;
    final chips = <Widget>[
      if (range != null)
        InputChip(
          avatar: const Icon(Icons.date_range, size: 18),
          label: Text('${shortDate(range.start)} – ${shortDate(range.end)}'),
          onPressed: onOpenSheet,
          onDeleted: () => onChanged(filter.copyWith(clearRange: true)),
        ),
      for (final tag in filter.tags)
        InputChip(
          avatar: const Icon(Icons.sell_outlined, size: 18),
          label: Text(tag),
          onPressed: onOpenSheet,
          onDeleted: () =>
              onChanged(filter.copyWith(tags: {...filter.tags}..remove(tag))),
        ),
      if (filter.sort != ShiftSort.newest)
        InputChip(
          avatar: const Icon(Icons.sort, size: 18),
          label: Text(filter.sort.label),
          onPressed: onOpenSheet,
          onDeleted: () => onChanged(filter.copyWith(sort: ShiftSort.newest)),
        ),
    ];
    if (chips.isEmpty) return const SizedBox(height: 4);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => Center(child: chips[index]),
      ),
    );
  }
}

/// "3 shifts · 7h 30m · SAR 562.50" for the shifts currently listed.
class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.results, required this.settings});

  final List<Shift> results;
  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final worked =
        results.fold(Duration.zero, (sum, shift) => sum + shift.duration);
    final parts = [
      '${results.length} ${results.length == 1 ? 'shift' : 'shifts'}',
      shiftDuration(worked),
      if (settings.hasRate)
        formatMoney(
            Shift.earningsFor(worked.inMilliseconds, settings.hourlyRate),
            settings.currencyCode),
    ];
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(parts.join(' · '),
          key: const Key('history-summary'),
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Text(label.toUpperCase(),
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.primary, letterSpacing: 0.8)),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: scheme.onErrorContainer))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      ),
    );
  }
}
