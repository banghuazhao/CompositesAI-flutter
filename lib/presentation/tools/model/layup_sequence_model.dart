import 'package:flutter/foundation.dart';

class LayupSequence {
  List<double>? layups;
  String stringValue = "";

  // set 方法
  set value(String value) {
    layups = [];
    String baseLayup = "";
    int rBefore = 1;
    bool symmetry = false;
    int rAfter = 1;

    if (value.split("]").length == 2 && value.split("]")[1] != "") {
      baseLayup = value.split("]")[0].replaceAll("[", "");
      String msn = value.split("]")[1];
      if (msn.contains('s')) {
        // symmetry
        symmetry = true;
        var r = msn.split('s');

        if (r.length == 2) {
          if (r[0] != "") {
            int? rBeforeTemp = int.tryParse(r[0]);
            if (rBeforeTemp != null) {
              rBefore = rBeforeTemp;
            } else {
              layups = null;
              return;
            }
          }
          if (r[1] != "") {
            int? rAfterTemp = int.tryParse(r[1]);
            if (rAfterTemp != null) {
              rAfter = rAfterTemp;
            } else {
              layups = null;
              return;
            }
          }
        }
      } else {
        // not symmetry
        symmetry = false;
        int? rBeforeTemp = int.tryParse(msn);
        if (rBeforeTemp != null) {
          rBefore = rBeforeTemp;
        } else {
          layups = null;
          return;
        }
      }
    } else {
      baseLayup = value.replaceAll("[", "").replaceAll("]", '');
    }

    for (String angleString in baseLayup.split('/')) {
      double? angle = double.tryParse(angleString);
      if (angle == null) {
        layups = null;
        return;
      }
      layups?.add(angle);
    }

    var layupsTemp = [...layups!];

    for (var i = 1; i < rBefore; i++) {
      for (var layup in layupsTemp) {
        layups?.add(layup);
      }
    }

    layupsTemp = [...layups!];

    if (symmetry) {
      var layupsTempReversed = layupsTemp.reversed;
      for (var layup in layupsTempReversed) {
        layups?.add(layup);
      }
    }

    layupsTemp = [...layups!];

    for (var i = 1; i < rAfter; i++) {
      for (var layup in layupsTemp) {
        layups?.add(layup);
      }
    }
    if (kDebugMode) {
      print(baseLayup);
      print(layups);
    }
  }

  isValid() {
    if (layups == null) {
      return false;
    } else if (layups!.length > 1000000) {
      return false;
    } else {
      return true;
    }
  }
}
