import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:linalg/matrix.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';

class Result6By6Matrix extends StatelessWidget {
  final String title;
  final Matrix matrix;

  const Result6By6Matrix({Key? key, required this.matrix, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          ListTile(
            title: AutoSizeText(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
            ),
          ),
          StaggeredGridView.countBuilder(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 6,
            itemCount: 36,
            itemBuilder: (BuildContext context, int index) {
              double value = matrix[index ~/ 6][index % 6];
              return Consumer<NumberPrecisionHelper>(builder: (context, precs, child) {
                return Center(
                  child: Container(
                    height: 30,
                    child: Center(
                      child: Text(value == 0 ? "0" : value.toStringAsExponential(precs.precision),
                          style: TextStyle(fontSize: 11), maxLines: 2),
                    ),
                  ),
                );
              });
            },
            staggeredTileBuilder: (int index) => const StaggeredTile.fit(1),
            mainAxisSpacing: 12,
            crossAxisSpacing: 4,
          ),
        ],
      ),
    );
  }
}
