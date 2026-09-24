import 'package:flutter/material.dart';

import '../model/unit_system.dart';

/// Numeric input used by the calculator cards.
///
/// The field shows its unit next to the label and re-reads [value] whenever
/// [revision] changes, which is how values picked from the material library
/// appear in fields the user may already have edited.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.unit = '',
    this.errorText,
    this.revision = 0,
    this.signed = false,
  });

  final String label;
  final String unit;
  final double? value;
  final ValueChanged<double?> onChanged;
  final String? errorText;
  final int revision;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label#$revision'),
      initialValue: formatInputNumber(value),
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: signed,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.all(12),
        border: const OutlineInputBorder(),
        labelText: withUnit(label, unit),
        errorText: errorText,
        errorMaxLines: 2,
      ),
      onChanged: (text) => onChanged(double.tryParse(text.trim())),
    );
  }
}

/// Formats a value for an input field without float noise: 181, 0.28, 2.25e-5.
String formatInputNumber(double? value) {
  if (value == null) return '';
  if (value == 0) return '0';
  final magnitude = value.abs();
  if (magnitude < 1e-3 || magnitude >= 1e7) {
    return _trimExponential(value.toStringAsExponential(4));
  }
  // Six significant digits keep unit conversions readable (26.2517).
  final text = double.parse(value.toStringAsPrecision(6)).toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

String _trimExponential(String text) {
  final parts = text.split('e');
  var mantissa = parts.first;
  if (mantissa.contains('.')) {
    mantissa = mantissa
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  return '${mantissa}e${parts.last.replaceFirst('+', '')}';
}

/// Card with a title row, optional help dialog and optional trailing action,
/// shared by the calculator input sections.
class InputCard extends StatelessWidget {
  const InputCard({
    super.key,
    required this.title,
    required this.children,
    this.help,
    this.action,
  });

  final String title;
  final Widget? help;
  final Widget? action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (help != null)
                  IconButton(
                    tooltip: 'About $title',
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => Dialog(
                        insetPadding: const EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
                          child: help,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            trailing: action,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays out fields two per row, padding an odd last row with a spacer.
class FieldGrid extends StatelessWidget {
  const FieldGrid({super.key, required this.fields});

  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: fields[i]),
          const SizedBox(width: 12),
          Expanded(
            child: i + 1 < fields.length ? fields[i + 1] : const SizedBox(),
          ),
        ],
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
