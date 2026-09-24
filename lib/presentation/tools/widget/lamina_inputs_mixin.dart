import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/failure_criteria.dart';
import '../model/material_library.dart';
import '../model/material_model.dart';
import '../model/thermal_model.dart';
import '../model/unit_system.dart';

/// Material-library and unit handling shared by calculator pages that take
/// lamina constants.
mixin LaminaInputsMixin<T extends StatefulWidget> on State<T> {
  TransverselyIsotropicMaterial get laminaMaterial;

  /// CTEs to fill from the library, when the page has them.
  TransverselyIsotropicCTE? get laminaCte => null;

  /// Strengths to fill from the library, when the page has them.
  LaminaStrengths? get laminaStrengths => null;

  /// Bumped whenever inputs are filled programmatically so fields refresh.
  int inputRevision = 0;

  Units get units => context.read<UnitSettings>().units;

  void applyLibraryMaterial(LibraryMaterial material) {
    final units = this.units;
    setState(() {
      material.applyToLamina(laminaMaterial, units);
      final cte = laminaCte;
      if (cte != null) material.applyCte(cte, units);
      final strengths = laminaStrengths;
      if (strengths != null) material.applyStrengths(strengths, units);
      inputRevision++;
    });
    final missing = [
      if (laminaStrengths != null && !material.hasStrengths) 'strengths',
    ];
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${material.name} has no ${missing.join(' or ')} data.'),
      ));
    }
  }

  LibraryMaterial? saveCurrentMaterial(String name) {
    return LibraryMaterial.fromLaminaInputs(
      name: name,
      units: units,
      material: laminaMaterial,
      cte: laminaCte,
      strengths: laminaStrengths,
    );
  }

  /// False when a modulus is far too large for the selected unit, which
  /// usually means it was typed in another unit (e.g. MPa instead of GPa).
  bool laminaModuliPlausible() {
    final limit = units.maxPlausibleModulus;
    return [laminaMaterial.e1, laminaMaterial.e2, laminaMaterial.g12]
        .every((value) => value == null || value <= limit);
  }
}
