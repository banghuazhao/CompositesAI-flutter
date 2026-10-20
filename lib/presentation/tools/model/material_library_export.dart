import 'dart:convert';

import 'material_library.dart';

/// Exports a snapshot of saved materials in their stored SI units.
///
/// Callers supply [MaterialLibrary.customMaterials], rather than a visible or
/// kind-filtered library list. No values are converted or rounded for display.
class MaterialLibraryExport {
  const MaterialLibraryExport._();

  static const Map<String, String> _units = {
    'e1': 'GPa',
    'e2': 'GPa',
    'g12': 'GPa',
    'nu12': 'unitless',
    'nu23': 'unitless',
    'alpha11': '1/°C',
    'alpha22': '1/°C',
    'xt': 'MPa',
    'xc': 'MPa',
    'yt': 'MPa',
    'yc': 'MPa',
    's12': 'MPa',
  };

  /// Produces the complete snapshot, or throws if any record is malformed.
  /// Invalid records are never silently dropped from the export.
  static String toJson(List<LibraryMaterial> customMaterials) {
    final snapshot = List<LibraryMaterial>.of(customMaterials, growable: false);
    final records = <Map<String, dynamic>>[];
    for (var index = 0; index < snapshot.length; index++) {
      final record = snapshot[index].toJson();
      final name = record['name'];
      if (record['id'] is! String ||
          name is! String ||
          name.trim().isEmpty ||
          record['source'] is! String ||
          !MaterialKind.values.any((kind) => kind.name == record['kind'])) {
        throw FormatException('Material ${index + 1} has invalid metadata.');
      }
      for (final property in _units.keys) {
        final value = record[property];
        if ((value == null && (property == 'e1' || property == 'nu12')) ||
            (value != null && (value is! num || !value.isFinite))) {
          throw FormatException(
              'Material ${index + 1} has an invalid $property value.');
        }
      }
      records.add(record);
    }
    return const JsonEncoder.withIndent('  ').convert({
      'schema': 'compositesai.custom-materials',
      'version': 1,
      'unitSystem': 'SI',
      'units': _units,
      'materials': records,
    });
  }
}
