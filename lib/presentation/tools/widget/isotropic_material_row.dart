import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/explain.dart';
import 'package:swiftcomp/presentation/tools/model/validate.dart';

import '../model/material_library.dart';
import '../model/unit_system.dart';
import 'material_library_sheet.dart';
import 'number_field.dart';

class IsotropicMaterialRow extends StatelessWidget {
  final String title;
  final IsotropicMaterial material;
  final bool validate;
  final int revision;
  final ValueChanged<LibraryMaterial>? onMaterialSelected;
  final MaterialFromInputs? saveCurrent;

  const IsotropicMaterialRow(
      {Key? key,
      required this.title,
      required this.material,
      required this.validate,
      this.revision = 0,
      this.onMaterialSelected,
      this.saveCurrent})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitSettings>().units;
    final onSelected = onMaterialSelected;
    return InputCard(
      title: title,
      help: Explain.getExplain(ExplainType.material, context),
      action: onSelected == null
          ? null
          : MaterialLibraryButton(
              kind: MaterialKind.matrix,
              onSelected: onSelected,
              saveCurrent: saveCurrent,
            ),
      children: [
        FieldGrid(fields: [
          NumberField(
            label: 'E',
            unit: units.modulus,
            value: material.e,
            revision: revision,
            errorText: validate ? validateModulusIn(material.e, units) : null,
            onChanged: (value) => material.e = value,
          ),
          NumberField(
            label: 'ν',
            value: material.nu,
            revision: revision,
            signed: true,
            errorText:
                validate ? validateIsotropicPoissonRatio(material.nu) : null,
            onChanged: (value) => material.nu = value,
          ),
        ]),
      ],
    );
  }
}
