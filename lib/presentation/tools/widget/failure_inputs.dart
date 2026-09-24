import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/failure_criteria.dart';
import '../model/mechanical_tensor_model.dart';
import '../model/unit_system.dart';
import '../model/validate.dart';
import 'number_field.dart';

/// Lamina strength inputs for the failure analysis.
class LaminaStrengthsRow extends StatelessWidget {
  const LaminaStrengthsRow({
    super.key,
    required this.strengths,
    required this.validate,
    this.revision = 0,
  });

  final LaminaStrengths strengths;
  final bool validate;
  final int revision;

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitSettings>().units;
    NumberField field(
      String label,
      double? value,
      ValueChanged<double?> onChanged,
    ) {
      return NumberField(
        label: label,
        unit: units.stress,
        value: value,
        revision: revision,
        errorText: validate ? validateStrength(value) : null,
        onChanged: onChanged,
      );
    }

    return InputCard(
      title: 'Lamina Strengths',
      help: const Text(
        'Enter strengths as positive magnitudes.\n\n'
        'Xt, Xc: longitudinal (fiber direction) tensile and compressive '
        'strength.\nYt, Yc: transverse tensile and compressive strength.\n'
        'S12: in-plane shear strength.',
      ),
      children: [
        FieldGrid(fields: [
          field('Xt', strengths.xt, (v) => strengths.xt = v),
          field('Xc', strengths.xc, (v) => strengths.xc = v),
          field('Yt', strengths.yt, (v) => strengths.yt = v),
          field('Yc', strengths.yc, (v) => strengths.yc = v),
          field('S12', strengths.s12, (v) => strengths.s12 = v),
        ]),
      ],
    );
  }
}

/// Force and moment resultants; empty fields count as zero.
class LaminateLoadsRow extends StatelessWidget {
  const LaminateLoadsRow({super.key, required this.loads});

  final LaminateStress loads;

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitSettings>().units;
    NumberField field(
      String label,
      String unit,
      double? value,
      ValueChanged<double?> onChanged,
    ) {
      return NumberField(
        label: label,
        unit: unit,
        value: value,
        signed: true,
        onChanged: onChanged,
      );
    }

    return InputCard(
      title: 'Applied Loads',
      help: const Text(
        'Force resultants N and moment resultants M per unit width, in '
        'laminate axes. Leave a field empty for zero.',
      ),
      children: [
        FieldGrid(fields: [
          field('N11', units.forceResultant, loads.N11, (v) => loads.N11 = v),
          field('M11', units.momentResultant, loads.M11, (v) => loads.M11 = v),
          field('N22', units.forceResultant, loads.N22, (v) => loads.N22 = v),
          field('M22', units.momentResultant, loads.M22, (v) => loads.M22 = v),
          field('N12', units.forceResultant, loads.N12, (v) => loads.N12 = v),
          field('M12', units.momentResultant, loads.M12, (v) => loads.M12 = v),
        ]),
      ],
    );
  }
}
