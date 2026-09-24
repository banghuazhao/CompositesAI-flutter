import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/presentation/tools/widget/legacy_staggered_grid.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/material_model.dart';
import 'package:swiftcomp/presentation/tools/model/volume_fraction_model.dart';
import 'package:swiftcomp/presentation/tools/page/UDFRC_rules_of_mixture_result_page.dart';
import 'package:swiftcomp/presentation/tools/model/DescriptionModels.dart';
import 'package:swiftcomp/presentation/tools/widget/description.dart';
import 'package:swiftcomp/presentation/tools/widget/isotropic_material_row.dart';
import 'package:swiftcomp/presentation/tools/widget/isotropic_thermal_constants_row.dart';
import 'package:swiftcomp/presentation/tools/widget/transversely_isotropic_row.dart';
import 'package:swiftcomp/presentation/tools/widget/volume_fraction_row.dart';

import '../../tools/model/thermal_model.dart';
import '../../tools/widget/analysis_type_row.dart';
import '../widget/transversely_thermal_constants_row.dart';
import 'package:provider/provider.dart';

import '../model/calc_report.dart';
import '../model/material_library.dart';
import '../model/unit_system.dart';

class RulesOfMixturePage extends StatefulWidget {
  const RulesOfMixturePage({Key? key}) : super(key: key);

  @override
  _RulesOfMixturePageState createState() => _RulesOfMixturePageState();
}

class _RulesOfMixturePageState extends State<RulesOfMixturePage> {
  AnalysisType analysisType = AnalysisType.elastic;
  TransverselyIsotropicMaterial fiberMaterial = TransverselyIsotropicMaterial();
  IsotropicMaterial matrixMaterial = IsotropicMaterial();
  VolumeFraction fiberVolumeFraction = VolumeFraction();
  bool validate = false;
  int _inputRevision = 0;

  Units get _units => context.read<UnitSettings>().units;

  void _applyFiber(LibraryMaterial material) {
    setState(() {
      material.applyToLamina(fiberMaterial, _units);
      material.applyCte(transverselyIsotropicCTE, _units);
      _inputRevision++;
    });
  }

  void _applyMatrix(LibraryMaterial material) {
    setState(() {
      material.applyToIsotropic(matrixMaterial, _units);
      material.applyIsotropicCte(isotropicCTE, _units);
      _inputRevision++;
    });
  }

  bool _moduliPlausible() {
    final limit = _units.maxPlausibleModulus;
    return [fiberMaterial.e1, fiberMaterial.e2, fiberMaterial.g12,
            matrixMaterial.e]
        .every((value) => value == null || value <= limit);
  }

  TransverselyIsotropicCTE transverselyIsotropicCTE =
      TransverselyIsotropicCTE();

  IsotropicCTE isotropicCTE = IsotropicCTE();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_outlined),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(S.of(context).UDFRC_Properties),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              validate = true;
            });
            _calculate();
          },
          label: Text(S.of(context).Calculate),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (_) {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: SafeArea(
              child: StaggeredGridView.countBuilder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  crossAxisCount: 8,
                  itemCount: itemList.length,
                  staggeredTileBuilder: (int index) => StaggeredTile.fit(
                      MediaQuery.of(context).size.width > 600 ? 4 : 8),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemBuilder: (BuildContext context, int index) {
                    return itemList[index];
                  })),
        ));
  }

  List<Widget> get itemList {
    return [
      AnalysisTypeRow(
        analysisType: analysisType,
        onChanged: (newValue) {
          setState(() {
            analysisType = newValue;
          });
        },
      ),
      TransverselyIsotropicRow(
        material: fiberMaterial,
        validate: validate,
        revision: _inputRevision,
        onMaterialSelected: _applyFiber,
        saveCurrent: (name) => LibraryMaterial.fromLaminaInputs(
          name: name,
          units: _units,
          material: fiberMaterial,
          cte: transverselyIsotropicCTE,
          kind: MaterialKind.fiber,
        ),
      ),
      if (analysisType == AnalysisType.thermalElastic)
        TransverselyThermalConstantsRow(
            material: transverselyIsotropicCTE,
            title: "Fiber CTEs",
            shouldConsider12: false,
            validate: validate,
            revision: _inputRevision),
      IsotropicMaterialRow(
        title: "Matrix Properties",
        material: matrixMaterial,
        validate: validate,
        revision: _inputRevision,
        onMaterialSelected: _applyMatrix,
        saveCurrent: (name) => LibraryMaterial.fromIsotropicInputs(
          name: name,
          units: _units,
          material: matrixMaterial,
          cte: isotropicCTE,
        ),
      ),
      if (analysisType == AnalysisType.thermalElastic)
        IsotropicThermalConstantsRow(
            material: isotropicCTE,
            title: "Matrix CTE",
            validate: validate,
            revision: _inputRevision),
      VolumeFractionRow(
          volumeFraction: fiberVolumeFraction, validate: validate),
      DescriptionItem(
          content: DescriptionModels.getDescription(
              DescriptionType.UDFRC_rules_of_mixtures, context))
    ];
  }

  void _calculate() {
    if (fiberMaterial.isValid() &&
        matrixMaterial.isValid() &&
        _moduliPlausible() &&
        fiberVolumeFraction.isValid()) {
      if (analysisType == AnalysisType.thermalElastic &&
          (!transverselyIsotropicCTE.isValid() || !isotropicCTE.isValid())) {
        return;
      }

      UDFRCRulesOfMixtureInput input = UDFRCRulesOfMixtureInput(
        analysisType: analysisType,
        E1_fiber: fiberMaterial.e1 ?? 0,
        E2_fiber: fiberMaterial.e2 ?? 0,
        G12_fiber: fiberMaterial.g12 ?? 0,
        nu12_fiber: fiberMaterial.nu12 ?? 0,
        nu23_fiber: fiberMaterial.nu23 ?? 0,
        alpha11_fiber: transverselyIsotropicCTE.alpha11 ?? 0,
        alpha22_fiber: transverselyIsotropicCTE.alpha22 ?? 0,
        E_matrix: matrixMaterial.e ?? 0,
        nu_matrix: matrixMaterial.nu ?? 0,
        alpha_matrix: isotropicCTE.alpha ?? 0,
        fiberVolumeFraction: fiberVolumeFraction.value ?? 0,
      );

      UDFRCRulesOfMixtureOutput output =
          UDFRCRulesOfMixtureCalculator.calculate(input);

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => RulesOfMixtureResultPage(
                    output: output,
                    inputs: _reportInputs(),
                  )));
    }
  }

  List<ReportSection> _reportInputs() {
    final units = _units;
    final isThermal = analysisType == AnalysisType.thermalElastic;
    return [
      ValuesSection('Fiber properties', [
        ReportEntry('E1', fiberMaterial.e1, units.modulus),
        ReportEntry('E2', fiberMaterial.e2, units.modulus),
        ReportEntry('G12', fiberMaterial.g12, units.modulus),
        ReportEntry('ν12', fiberMaterial.nu12),
        ReportEntry('ν23', fiberMaterial.nu23),
        if (isThermal) ...[
          ReportEntry('ɑ11', transverselyIsotropicCTE.alpha11, units.cte),
          ReportEntry('ɑ22', transverselyIsotropicCTE.alpha22, units.cte),
        ],
      ]),
      ValuesSection('Matrix properties', [
        ReportEntry('E', matrixMaterial.e, units.modulus),
        ReportEntry('ν', matrixMaterial.nu),
        if (isThermal) ReportEntry('ɑ', isotropicCTE.alpha, units.cte),
      ]),
      ValuesSection('Microstructure', [
        ReportEntry('Fiber volume fraction', fiberVolumeFraction.value),
      ]),
    ];
  }
}
