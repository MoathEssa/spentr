import 'package:flutter/material.dart';

import '../../core/date_labels.dart';
import '../../core/money.dart';
import '../../core/routes.dart';
import '../../core/shift_formatters.dart';
import '../../data/models/shift.dart';
import '../../state/settings_provider.dart';

/// One saved shift, used on Home, History and the Day details sheet.
/// Tapping it opens Shift details.
class ShiftTile extends StatelessWidget {
  const ShiftTile({
    super.key,
    required this.shift,
    required this.settings,
    this.showDate = true,
    this.onOpen,
  });

  final Shift shift;
  final SettingsProvider settings;

  /// False inside the Day details sheet, where the date is the sheet title.
  final bool showDate;

  /// Runs before Shift details is pushed (the Day sheet closes itself first).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = settings.hasRate
        ? formatMoney(
            shift.earnings(settings.hourlyRate), settings.currencyCode)
        : 'Rate not set';
    final when = showDate
        ? '${shortDate(shift.start)} · ${clockTime(shift.start)}–${clockTime(shift.end)}'
        : '${clockTime(shift.start)}–${clockTime(shift.end)}';
    return Card(
      child: ListTile(
        title: Text(
          shift.note.isEmpty ? 'Untitled shift' : shift.note,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          shift.tags.isEmpty ? when : '$when\n${shift.tags.join(' / ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: shift.tags.isNotEmpty,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(shiftDuration(shift.duration),
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(money,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
        onTap: () {
          final navigator = Navigator.of(context);
          onOpen?.call();
          navigator.pushNamed(AppRoutes.shiftDetail, arguments: shift.id);
        },
      ),
    );
  }
}
