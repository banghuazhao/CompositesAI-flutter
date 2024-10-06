import 'package:linalg/linalg.dart';

// Extension on Matrix class to convert it to a List<List<double>>
extension MatrixToListExtension on Matrix {
  List<List<double>> toListOfLists() {
    List<List<double>> list = [];
    for (int i = 0; i < this.m; i++) {
      List<double> row = [];
      for (int j = 0; j < this.n; j++) {
        row.add(this[i][j]);
      }
      list.add(row);
    }
    return list;
  }
}