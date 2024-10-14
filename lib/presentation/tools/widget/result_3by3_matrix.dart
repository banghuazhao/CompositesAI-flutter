import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';

class Result3By3Matrix extends StatelessWidget {
  final String title;
  final List<List<double>> matrixList;

  const Result3By3Matrix({Key? key, required this.matrixList, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          StaggeredGridView.countBuilder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 6,
            itemCount: 9,
            itemBuilder: (BuildContext context, int index) {
              double value = matrixList[index ~/ 3][index % 3];
              return Consumer<NumberPrecisionHelper>(builder: (context, precs, child) {
                return Center(
                  child: Container(
                    height: 40,
                    child: Center(
                      child: Text(
                        value == 0 ? "0" : value.toStringAsExponential(precs.precision),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                );
              });
            },
            staggeredTileBuilder: (int index) => const StaggeredTile.fit(2),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
        ],
      ),
    );
  }
}
