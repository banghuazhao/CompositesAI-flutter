import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/widget/legacy_staggered_grid.dart';

import '../model/calc_report.dart';
import '../model/failure_criteria.dart';
import '../model/layer_thickness.dart';
import '../model/layup_sequence_model.dart';
import '../model/material_model.dart';
import '../model/mechanical_tensor_model.dart';
import '../model/unit_system.dart';
import '../widget/description.dart';
import '../widget/failure_inputs.dart';
import '../widget/lamina_constants_row.dart';
import '../widget/lamina_inputs_mixin.dart';
import '../widget/layer_thickness_row.dart';
import '../widget/layup_sequence_row.dart';
import 'laminate_failure_result_page.dart';

const String laminateFailureTitle = 'Laminate Failure Analysis';

/// Describes the failure analysis on the tools list and the input page.
Widget laminateFailureDescription(BuildContext context) {
  return Text(
    'Ply-by-ply failure analysis of a laminate under force and moment '
    'resultants using classical lamination theory.\n\n'
    'Stresses are evaluated at the top and bottom of every ply in material '
    'axes and checked with the maximum stress, Tsai-Hill, Tsai-Wu and Hashin '
    'criteria. The strength ratio R is the factor on the applied loads that '
    'causes first-ply failure (R < 1 means the ply has already failed).\n\n'
    'Assumptions: linear elastic plies, mechanical loads only (no thermal '
    'residual stresses), Tsai-Wu interaction F12 = -½√(F11·F22), and Hashin '
    'transverse shear strength Yc/2.',
    style: Theme.of(context).textTheme.bodyMedium,
  );
}

class LaminateFailurePage extends StatefulWidget {
  const LaminateFailurePage({super.key});

  @override
  State<LaminateFailurePage> createState() => _LaminateFailurePageState();
}

class _LaminateFailurePageState extends State<LaminateFailurePage>
    with LaminaInputsMixin {
  final TransverselyIsotropicMaterial material = TransverselyIsotropicMaterial();
  final LaminaStrengths strengths = LaminaStrengths();
  final LayupSequence layupSequence = LayupSequence();
  final LayerThickness layerThickness = LayerThickness();
  final LaminateStress loads = LaminateStress();
  bool validate = false;

  @override
  TransverselyIsotropicMaterial get laminaMaterial => material;

  @override
  LaminaStrengths? get laminaStrengths => strengths;

  @override
  Widget build(BuildContext context) {
    final items = [
      LaminaConstantsRow(
        material: material,
        validate: validate,
        isPlaneStress: true,
        revision: inputRevision,
        onMaterialSelected: applyLibraryMaterial,
        saveCurrent: saveCurrentMaterial,
      ),
      LaminaStrengthsRow(
        strengths: strengths,
        validate: validate,
        revision: inputRevision,
      ),
      LayupSequenceRow(layupSequence: layupSequence, validate: validate),
      LayerThicknessPage(layerThickness: layerThickness, validate: validate),
      LaminateLoadsRow(loads: loads),
      DescriptionItem(content: laminateFailureDescription(context)),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_outlined),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(laminateFailureTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() => validate = true);
          _calculate();
        },
        label: Text(S.of(context).Calculate),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (_) => FocusScope.of(context).requestFocus(FocusNode()),
        child: SafeArea(
          child: StaggeredGridView.countBuilder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            crossAxisCount: 8,
            itemCount: items.length,
            staggeredTileBuilder: (int index) => StaggeredTile.fit(
                MediaQuery.of(context).size.width > 600 ? 4 : 8),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemBuilder: (BuildContext context, int index) => items[index],
          ),
        ),
      ),
    );
  }

  void _calculate() {
    final layups = layupSequence.layups;
    if (!material.isValidInPlane() ||
        !laminaModuliPlausible() ||
        !strengths.isValid() ||
        !layupSequence.isValid() ||
        layups == null ||
        layups.isEmpty ||
        !layerThickness.isValid() ||
        layerThickness.value! <= 0) {
      return;
    }

    final units = this.units;
    const toStress = Units.modulusToStress;
    final forces = [loads.N11 ?? 0, loads.N22 ?? 0, loads.N12 ?? 0];
    final moments = [loads.M11 ?? 0, loads.M22 ?? 0, loads.M12 ?? 0];
    if ([...forces, ...moments].every((value) => value == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter at least one non-zero load.'),
      ));
      return;
    }

    final LaminateFailureResult result;
    try {
      result = LaminateFailureAnalysis.analyze(
        e1: material.e1! * toStress,
        e2: material.e2! * toStress,
        g12: material.g12! * toStress,
        nu12: material.nu12!,
        layup: layups,
        plyThickness: layerThickness.value!,
        forces: forces,
        moments: moments,
        strengths: strengths,
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('The laminate stiffness matrix is singular; '
            'check the material constants.'),
      ));
      return;
    }

    final inputs = <ReportSection>[
      ReportInputs.lamina(material, units),
      ValuesSection('Lamina strengths', [
        ReportEntry('Xt', strengths.xt, units.stress),
        ReportEntry('Xc', strengths.xc, units.stress),
        ReportEntry('Yt', strengths.yt, units.stress),
        ReportEntry('Yc', strengths.yc, units.stress),
        ReportEntry('S12', strengths.s12, units.stress),
      ]),
      ReportInputs.layup(
          layupSequence.stringValue, layerThickness.value, units),
      ValuesSection('Applied loads', [
        ReportEntry('N11', forces[0], units.forceResultant),
        ReportEntry('N22', forces[1], units.forceResultant),
        ReportEntry('N12', forces[2], units.forceResultant),
        ReportEntry('M11', moments[0], units.momentResultant),
        ReportEntry('M22', moments[1], units.momentResultant),
        ReportEntry('M12', moments[2], units.momentResultant),
      ]),
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LaminateFailureResultPage(
          result: result,
          inputs: inputs,
        ),
      ),
    );
  }
}
