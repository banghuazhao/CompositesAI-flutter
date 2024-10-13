class LayupParser {
  static List<double>? parse(String layupSequence) {
    List<double> layups = [];
    String baseLayup = "";
    int rBefore = 1;
    bool symmetry = false;
    int rAfter = 1;

    if (layupSequence.split("]").length == 2 && layupSequence.split("]")[1] != "") {
      baseLayup = layupSequence.split("]")[0].replaceAll("[", "");
      String msn = layupSequence.split("]")[1];
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
              return null;
            }
          }
          if (r[1] != "") {
            int? rAfterTemp = int.tryParse(r[1]);
            if (rAfterTemp != null) {
              rAfter = rAfterTemp;
            } else {
              return null;
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
          return null;
        }
      }
    } else {
      baseLayup = layupSequence.replaceAll("[", "").replaceAll("]", '');
    }

    for (String angleString in baseLayup.split('/')) {
      double? angle = double.tryParse(angleString);
      if (angle == null) {
        return null;
      }
      layups?.add(angle);
    }

    var layupsTemp = [...layups!];

    for (var i = 1; i < rBefore; i++) {
      for (var layup in layupsTemp) {
        layups?.add(layup);
      }
    }

    if (layups != null) {
      layupsTemp = [...layups];
    }

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
    return layups;
  }
}