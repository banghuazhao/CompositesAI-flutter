import 'package:composite_calculator/models/lamina_stress_strain_output.dart';
import 'package:composite_calculator/models/tensor_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/presentation/more/views/tool_setting_page.dart';

import '../widget/result_3by3_matrix.dart';

class LaminaStressStrainResult extends StatefulWidget {
  final LaminaStressStrainOutput output;

  const LaminaStressStrainResult({Key? key, required this.output})
      : super(key: key);

  @override
  _LaminaStressStrainResultState createState() =>
      _LaminaStressStrainResultState();
}

class _LaminaStressStrainResultState extends State<LaminaStressStrainResult> {
  @override
  Widget build(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon:
            const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ToolSettingPage()));
              },
              icon: const Icon(Icons.settings_rounded),
            ),
          ],
          title: Text(S
              .of(context)
              .Results),
        ),
        body: SafeArea(
          child: StaggeredGridView.countBuilder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              crossAxisCount: 8,
              itemCount: resultList.length,
              staggeredTileBuilder: (int index) =>
                  StaggeredTile.fit(
                      MediaQuery
                          .of(context)
                          .size
                          .width > 600 ? 4 : 8),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemBuilder: (BuildContext context, int index) {
                return resultList[index];
              }),
        ));
  }

  List<Widget> get resultList {
    return [
      ResultPlaneStressStrainRow(
        output: widget.output,
      ),
      Result3By3Matrix(
        title: S
            .of(context)
            .Stiffness_Matrix_Q,
        matrixList: widget.output.Q,
      ),
      Result3By3Matrix(
        title: S
            .of(context)
            .Compliance_Matrix_S,
        matrixList: widget.output.S,
      ),
    ];
  }
}

class ResultPlaneStressStrainRow extends StatelessWidget {
  final LaminaStressStrainOutput output;

  const ResultPlaneStressStrainRow({
    Key? key,
    required this.output,
  }) : super(key: key);

  bool get isStress {
    return output.tensorType == TensorType.stress;
  }

  @override
  Widget build(BuildContext context) {
    getResultString(int position) {
      if (isStress) {
        if (position == 0) {
          return output.sigma11.toStringAsExponential(3);
        } else if (position == 1) {
          return output.sigma22.toStringAsExponential(3);
        } else {
          return output.sigma12.toStringAsExponential(3);
        }
      } else {
        if (position == 0) {
          return output.epsilon11.toStringAsExponential(3);
        } else if (position == 1) {
          return output.epsilon22.toStringAsExponential(3);
        } else {
          return output.gamma12.toStringAsExponential(3);
        }
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
              style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium,
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
                      isStress ? "σ11" : "ε11",
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(getResultString(0),
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodySmall)
                  ],
                ),
                const SizedBox(
                  width: 8,
                ),
                Column(
                  children: [
                    Text(
                      isStress ? "σ22" : "ε22",
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(getResultString(1),
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodySmall)
                  ],
                ),
                const SizedBox(
                  width: 8,
                ),
                Column(
                  children: [
                    Text(
                      isStress ? "σ12" : "γ12",
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(getResultString(2),
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodySmall)
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
