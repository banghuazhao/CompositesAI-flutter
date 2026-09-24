import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/explain.dart';
import 'package:swiftcomp/presentation/tools/model/validate.dart';

import '../model/material_library.dart';
import '../model/unit_system.dart';
import 'material_library_sheet.dart';
import 'number_field.dart';

class TransverselyIsotropicRow extends StatelessWidget {
  final TransverselyIsotropicMaterial material;
  final bool validate;
  final int revision;
  final ValueChanged<LibraryMaterial>? onMaterialSelected;
  final MaterialFromInputs? saveCurrent;

  const TransverselyIsotropicRow(
      {Key? key,
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
      title: 'Fiber Properties',
      help: Explain.getExplain(ExplainType.material, context),
      action: onSelected == null
          ? null
          : MaterialLibraryButton(
              kind: MaterialKind.fiber,
              onSelected: onSelected,
              saveCurrent: saveCurrent,
            ),
      children: [
        FieldGrid(fields: [
          NumberField(
            label: 'E1',
            unit: units.modulus,
            value: material.e1,
            revision: revision,
            errorText: validate ? validateModulusIn(material.e1, units) : null,
            onChanged: (value) => material.e1 = value,
          ),
          NumberField(
            label: 'E2',
            unit: units.modulus,
            value: material.e2,
            revision: revision,
            errorText: validate ? validateModulusIn(material.e2, units) : null,
            onChanged: (value) => material.e2 = value,
          ),
          NumberField(
            label: 'G12',
            unit: units.modulus,
            value: material.g12,
            revision: revision,
            errorText:
                validate ? validateModulusIn(material.g12, units) : null,
            onChanged: (value) => material.g12 = value,
          ),
          NumberField(
            label: 'ν12',
            value: material.nu12,
            revision: revision,
            signed: true,
            errorText: validate ? validatePoissonRatio(material.nu12) : null,
            onChanged: (value) => material.nu12 = value,
          ),
          NumberField(
            label: 'ν23',
            value: material.nu23,
            revision: revision,
            signed: true,
            errorText: validate ? validatePoissonRatio(material.nu23) : null,
            onChanged: (value) => material.nu23 = value,
          ),
        ]),
      ],
    );
  }
}
