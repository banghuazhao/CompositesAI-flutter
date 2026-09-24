import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/tools/model/explain.dart';
import 'package:swiftcomp/presentation/tools/model/validate.dart';

import '../../tools/model/thermal_model.dart';
import '../model/unit_system.dart';
import 'number_field.dart';

class IsotropicThermalConstantsRow extends StatelessWidget {
  final IsotropicCTE material;
  final String title;
  final bool validate;
  final int revision;

  const IsotropicThermalConstantsRow(
      {Key? key,
      required this.material,
      this.title = "CTEs",
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
            label: 'ɑ',
            unit: units.cte,
            value: material.alpha,
            revision: revision,
            errorText: validate ? validateModulus(material.alpha) : null,
            onChanged: (value) => material.alpha = value,
          ),
        ]),
      ],
    );
  }
}
