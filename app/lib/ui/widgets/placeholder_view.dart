import 'package:flutter/material.dart';

/// A navigation action on a placeholder screen.
class PlaceholderAction {
  const PlaceholderAction(this.label, this.icon, this.onPressed,
      {this.primary = false});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
}

/// Body shared by every Phase 2 placeholder screen: what the screen is for,
/// the interface states designed for it in Figma, and buttons for the
/// navigation it will have. Replaced by the real UI in Phase 3.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({
    super.key,
    required this.purpose,
    this.states = const [],
    this.actions = const [],
  });

  final String purpose;
  final List<String> states;
  final List<PlaceholderAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  label: const Text('Phase 2 placeholder'),
                  backgroundColor: scheme.secondaryContainer,
                  labelStyle: TextStyle(color: scheme.onSecondaryContainer),
                  side: BorderSide.none,
                ),
                const SizedBox(height: 12),
                Text(purpose, style: theme.textTheme.bodyLarge),
                if (states.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('DESIGNED STATES',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final state in states)
                        Chip(
                            label: Text(state),
                            visualDensity: VisualDensity.compact),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: action.primary
                ? FilledButton.icon(
                    onPressed: action.onPressed,
                    icon: Icon(action.icon),
                    label: Text(action.label),
                  )
                : OutlinedButton.icon(
                    onPressed: action.onPressed,
                    icon: Icon(action.icon),
                    label: Text(action.label),
                  ),
          ),
      ],
    );
  }
}
