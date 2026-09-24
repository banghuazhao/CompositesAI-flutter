import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/unit_system.dart';

/// Lets the user choose the calculator unit system.
Future<void> showUnitSystemPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final settings = context.watch<UnitSettings>();
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculator units',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Inputs, results and exports use these units. Values you '
                'have already typed are not converted.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              RadioGroup<UnitSystem>(
                groupValue: settings.system,
                onChanged: (value) {
                  if (value != null) settings.setSystem(value);
                },
                child: Column(
                  children: [
                    for (final system in UnitSystem.values)
                      RadioListTile<UnitSystem>(
                        value: system,
                        contentPadding: EdgeInsets.zero,
                        title: Text(Units.of(system).name),
                        subtitle: Text(_details(Units.of(system))),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _details(Units units) =>
    'Moduli ${units.modulus} · stress ${units.stress} · '
    'length ${units.length} · loads ${units.forceResultant}';

/// Compact app bar button showing the current unit system.
class UnitSystemButton extends StatelessWidget {
  const UnitSystemButton({super.key});

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitSettings>().units;
    return TextButton.icon(
      onPressed: () => showUnitSystemPicker(context),
      icon: const Icon(Icons.straighten_rounded, size: 18),
      label: Text(units.isSI ? 'SI' : 'US'),
    );
  }
}
