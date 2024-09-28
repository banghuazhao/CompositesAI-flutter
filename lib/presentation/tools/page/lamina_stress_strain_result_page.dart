import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/tools/model/mechanical_tensor_model.dart';
import 'package:swiftcomp/presentation/tools/widget/result_plane_compliance_matrix.dart';
import 'package:swiftcomp/presentation/tools/widget/result_plane_stiffness_matrix.dart';
import 'package:swiftcomp/presentation/more/tool_setting_page.dart';
import 'package:vector_math/vector_math.dart' as VMath;

class LaminaStressStrainResult extends StatefulWidget {
  final MechanicalTensor resultTensor;
  final VMath.Matrix3 Q_bar;
  final VMath.Matrix3 S_bar;

  const LaminaStressStrainResult(
      {Key? key, required this.resultTensor, required this.Q_bar, required this.S_bar})
      : super(key: key);

  @override
  _LaminaStressStrainResultState createState() => _LaminaStressStrainResultState();
}

class _LaminaStressStrainResultState extends State<LaminaStressStrainResult> {
  @override
  Widget build(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const ToolSettingPage()));
              },
              icon: const Icon(Icons.settings_rounded),
            ),
          ],
          title: Text(S.of(context).Results),
        ),
        body: SafeArea(
          child: StaggeredGridView.countBuilder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              crossAxisCount: 8,
              itemCount: 3,
              staggeredTileBuilder: (int index) =>
                  StaggeredTile.fit(MediaQuery.of(context).size.width > 600 ? 4 : 8),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemBuilder: (BuildContext context, int index) {
                return [
                  ResultPlaneStressStrainRow(
                    mechanicalTensor: widget.resultTensor,
                  ),
                  ResultPlaneStiffnessMatrix(
                    Q_bar: widget.Q_bar,
                  ),
                  ResultPlaneComplianceMatrix(
                    S_bar: widget.S_bar,
                  )
                ][index];
              }),
        ));
  }
}

class ResultPlaneStressStrainRow extends StatelessWidget {
  final MechanicalTensor mechanicalTensor;

  const ResultPlaneStressStrainRow({
    Key? key,
    required this.mechanicalTensor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    getResultString(int position) {
      if (position == 0) {
        double? value = (mechanicalTensor is PlaneStress)
            ? (mechanicalTensor as PlaneStress).sigma11
            : (mechanicalTensor as PlaneStrain).epsilon11;
        return (value ?? 0).toStringAsExponential(3);
      } else if (position == 1) {
        double? value = (mechanicalTensor is PlaneStress)
            ? (mechanicalTensor as PlaneStress).sigma22
            : (mechanicalTensor as PlaneStrain).epsilon22;
        return (value ?? 0).toStringAsExponential(3);
      } else {
        double? value = (mechanicalTensor is PlaneStress)
            ? (mechanicalTensor as PlaneStress).sigma12
            : (mechanicalTensor as PlaneStrain).gamma12;
        return (value ?? 0).toStringAsExponential(3);
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              "Result",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      (mechanicalTensor is PlaneStress) ? "σ11" : "ε11",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(getResultString(0), style: Theme.of(context).textTheme.bodySmall)
                  ],
                ),
                const SizedBox(
                  width: 8,
                ),
                Column(
                  children: [
                    Text(
                      (mechanicalTensor is PlaneStress) ? "σ22" : "ε22",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(getResultString(1), style: Theme.of(context).textTheme.bodySmall)
                  ],
                ),
                const SizedBox(
                  width: 8,
                ),
                Column(
                  children: [
                    Text(
                      (mechanicalTensor is PlaneStress) ? "σ12" : "γ12",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(getResultString(2), style: Theme.of(context).textTheme.bodySmall)
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
