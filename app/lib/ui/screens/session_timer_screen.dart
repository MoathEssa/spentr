import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../core/routes.dart';
import '../../core/shift_formatters.dart';
import '../../data/models/active_session.dart';
import '../../data/models/shift.dart';
import '../../state/settings_provider.dart';
import '../widgets/confirm_dialog.dart';

/// Shows the open shift's worked time and live earnings.
///
/// Elapsed time comes from [ActiveSession] timestamps. The one-second ticker
/// only redraws the screen. Saving the session across restarts, the ongoing
/// notification, and turning Finish into a stored shift belong to
/// SessionProvider, which is not in the project yet.
class SessionTimerScreen extends StatefulWidget {
  const SessionTimerScreen({
    super.key,
    this.initialSession,
    this.now,
    this.enableTicker = true,
  });

  final ActiveSession? initialSession;
  final DateTime Function()? now;
  final bool enableTicker;

  @override
  State<SessionTimerScreen> createState() => _SessionTimerScreenState();
}

class _SessionTimerScreenState extends State<SessionTimerScreen>
    with WidgetsBindingObserver {
  late DateTime Function() _now;
  late ActiveSession _session;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = widget.now ?? DateTime.now;
    final now = _now();
    _session = widget.initialSession ??
        ActiveSession(
          start: now,
          status: SessionStatus.running,
          segmentStart: now,
        );
    if (widget.enableTicker) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  Duration _worked(DateTime now) {
    final worked = _session.workedAt(now);
    return worked.isNegative ? Duration.zero : worked;
  }

  void _togglePause() {
    final now = _now();
    setState(() {
      if (_session.isRunning) {
        final workedMs = _session.workedAt(now).inMilliseconds;
        _session = ActiveSession(
          start: _session.start,
          status: SessionStatus.paused,
          accumulatedMs: workedMs < 0 ? 0 : workedMs,
          note: _session.note,
          tags: _session.tags,
        );
      } else {
        _session = ActiveSession(
          start: _session.start,
          status: SessionStatus.running,
          accumulatedMs: _session.accumulatedMs,
          segmentStart: now,
          note: _session.note,
          tags: _session.tags,
        );
      }
    });
  }

  Future<void> _finish() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Ready to finish?',
      message: 'Save this shift to your history.',
      confirmLabel: 'Finish & save shift',
      cancelLabel: 'Keep tracking',
    );
    if (confirmed && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.shiftDetail);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel this shift?',
      message: 'This tracked time will be discarded. '
          'Your other shifts will stay saved.',
      confirmLabel: 'Discard shift',
      cancelLabel: 'Keep tracking',
    );
    if (confirmed && mounted) Navigator.pop(context);
  }

  String _clock(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(safe.inHours)}:${two(safe.inMinutes.remainder(60))}:${two(safe.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final now = _now();
    final worked = _worked(now);
    final wall = now.difference(_session.start);
    final paused = wall - worked;
    final earnings = Shift.earningsFor(
      worked.inMilliseconds,
      settings.hourlyRate,
    );
    final pausedLabel =
        paused > Duration.zero ? ' · ${shiftDuration(paused)} paused' : '';
    return Scaffold(
      appBar: AppBar(title: const Text('Current shift')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: Icon(
                      _session.isRunning ? Icons.circle : Icons.pause,
                      size: 14,
                    ),
                    label: Text(_session.isRunning ? 'Tracking' : 'Paused'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_clock(worked), style: theme.textTheme.displaySmall),
                const SizedBox(height: 8),
                if (settings.hasRate) ...[
                  Text(
                    formatMoney(earnings, settings.currencyCode),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'At your rate of ${formatMoney(settings.hourlyRate, settings.currencyCode)} / hour',
                  ),
                ] else
                  Text(
                    'Set an hourly rate in Settings to see earnings.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Started ${shiftDateTime(_session.start)}$pausedLabel',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _togglePause,
                  icon:
                      Icon(_session.isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(
                    _session.isRunning ? 'Pause shift' : 'Continue shift',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.check),
                  label: const Text('Finish shift'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _cancel,
                  child: const Text('Cancel shift'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
