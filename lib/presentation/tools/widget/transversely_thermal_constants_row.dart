import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/tools/model/explain.dart';
import 'package:swiftcomp/presentation/tools/model/validate.dart';

import '../../tools/model/thermal_model.dart';
import '../model/unit_system.dart';
import 'number_field.dart';

class TransverselyThermalConstantsRow extends StatelessWidget {
  final TransverselyIsotropicCTE material;
  final String title;
  final bool shouldConsider12;
  final bool validate;
  final int revision;

  const TransverselyThermalConstantsRow(
      {Key? key,
      required this.material,
      this.title = "CTEs",
      this.shouldConsider12 = true,
      required this.validate,
      this.revision = 0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitSettings>().units;
    return InputCard(
      title: title,
      help: Explain.getExplain(ExplainType.material, context),
      children: [
        FieldGrid(fields: [
          NumberField(
            label: 'ɑ11',
            unit: units.cte,
            value: material.alpha11,
            revision: revision,
            signed: true,
            errorText: validate ? validateCTEs(material.alpha11) : null,
            onChanged: (value) => material.alpha11 = value,
          ),
          NumberField(
            label: 'ɑ22',
            unit: units.cte,
            value: material.alpha22,
            revision: revision,
            signed: true,
            errorText: validate ? validateCTEs(material.alpha22) : null,
            onChanged: (value) => material.alpha22 = value,
          ),
          if (shouldConsider12)
            NumberField(
              label: 'ɑ12',
              unit: units.cte,
              value: material.alpha12,
              revision: revision,
              signed: true,
              errorText: validate ? validateCTEs(material.alpha12) : null,
              onChanged: (value) => material.alpha12 = value,
            ),
        ]),
      ],
    );
  }
}
