import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../data/models/shift.dart';

/// Shared hourly-rate editor for first-run setup and Settings.
class HourlyRateForm extends StatefulWidget {
  const HourlyRateForm({
    super.key,
    required this.initialRate,
    required this.initialCurrency,
    required this.previewHeading,
    required this.previewDuration,
    required this.previewText,
    required this.submitLabel,
    required this.onSubmit,
    this.heading,
    this.subheading,
    this.footnote,
    this.saving = false,
    this.saveError,
  });

  static const rateFieldKey = Key('hourlyRateField');
  static const currencyMenuKey = Key('currencyMenu');

  final double initialRate;
  final String initialCurrency;
  final String? heading;
  final String? subheading;
  final String previewHeading;
  final Duration previewDuration;
  final String Function(String money) previewText;
  final String? footnote;
  final String submitLabel;
  final bool saving;
  final String? saveError;
  final Future<void> Function(double rate, String currencyCode) onSubmit;

  @override
  State<HourlyRateForm> createState() => _HourlyRateFormState();
}

class _HourlyRateFormState extends State<HourlyRateForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rate;
  late String _currency;
  var _dirty = false;

  @override
  void initState() {
    super.initState();
    _rate = TextEditingController(text: _rateText(widget.initialRate));
    _currency = _knownCurrency(widget.initialCurrency);
  }

  @override
  void didUpdateWidget(HourlyRateForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dirty) return;
    if (oldWidget.initialRate != widget.initialRate) {
      _rate.text = _rateText(widget.initialRate);
    }
    if (oldWidget.initialCurrency != widget.initialCurrency) {
      _currency = _knownCurrency(widget.initialCurrency);
    }
  }

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  String _rateText(double rate) => rate > 0 ? rate.toStringAsFixed(2) : '';

  String _knownCurrency(String code) =>
      isSupportedCurrency(code) ? code : supportedCurrencies.first.code;

  Future<void> _submit() async {
    if (widget.saving || !_formKey.currentState!.validate()) return;
    final rate = RateInput.tryParse(_rate.text);
    if (rate == null) return;
    await widget.onSubmit(rate, _currency);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.heading != null) ...[
            Text(widget.heading!, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
          ],
          if (widget.subheading != null) ...[
            Text(
              widget.subheading!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
          ],
          TextFormField(
            key: HourlyRateForm.rateFieldKey,
            controller: _rate,
            enabled: !widget.saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(labelText: 'Hourly rate'),
            validator: RateInput.validate,
            onChanged: (_) => _dirty = true,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          DropdownMenu<String>(
            key: HourlyRateForm.currencyMenuKey,
            initialSelection: _currency,
            enabled: !widget.saving,
            expandedInsets: EdgeInsets.zero,
            requestFocusOnTap: false,
            label: const Text('Currency'),
            dropdownMenuEntries: [
              for (final currency in supportedCurrencies)
                DropdownMenuEntry(value: currency.code, label: currency.label),
            ],
            onSelected: (value) {
              if (value == null) return;
              setState(() {
                _dirty = true;
                _currency = value;
              });
            },
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _rate,
            builder: (context, value, _) {
              final rate = RateInput.tryParse(value.text);
              final body = rate == null
                  ? 'Enter a valid rate to preview earnings.'
                  : widget.previewText(formatMoney(
                      Shift.earningsFor(
                        widget.previewDuration.inMilliseconds,
                        rate,
                      ),
                      _currency,
                    ));
              return Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.previewHeading,
                          style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(body),
                    ],
                  ),
                ),
              );
            },
          ),
          if (widget.footnote != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.footnote!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (widget.saveError != null) ...[
            const SizedBox(height: 12),
            Text(widget.saveError!, style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.saving ? null : _submit,
            child: widget.saving
                ? const Text('Saving...')
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
