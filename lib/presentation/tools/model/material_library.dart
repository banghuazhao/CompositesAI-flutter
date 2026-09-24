import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../util/others.dart';
import 'failure_criteria.dart';
import 'material_model.dart';
import 'thermal_model.dart';
import 'unit_system.dart';

/// What a library entry describes, which decides where it can be used.
enum MaterialKind { lamina, fiber, matrix }

extension MaterialKindLabel on MaterialKind {
  String get label => switch (this) {
        MaterialKind.lamina => 'Unidirectional lamina',
        MaterialKind.fiber => 'Fiber',
        MaterialKind.matrix => 'Matrix',
      };
}

/// A material stored in SI units: moduli in GPa, strengths in MPa and
/// thermal expansion in 1/°C. Values are converted to the selected
/// [UnitSystem] when they are applied to calculator inputs.
///
/// Laminae and fibers are transversely isotropic (E1, E2, G12, ν12, ν23);
/// matrices are isotropic and use [e1] and [nu12] as E and ν.
@immutable
class LibraryMaterial {
  const LibraryMaterial({
    required this.id,
    required this.name,
    required this.kind,
    this.source = '',
    this.isCustom = false,
    required this.e1,
    this.e2,
    this.g12,
    required this.nu12,
    this.nu23,
    this.alpha11,
    this.alpha22,
    this.xt,
    this.xc,
    this.yt,
    this.yc,
    this.s12,
  });

  final String id;
  final String name;
  final MaterialKind kind;
  final String source;
  final bool isCustom;

  final double e1;
  final double? e2;
  final double? g12;
  final double nu12;
  final double? nu23;
  final double? alpha11;
  final double? alpha22;
  final double? xt;
  final double? xc;
  final double? yt;
  final double? yc;
  final double? s12;

  bool get hasCte => alpha11 != null;
  bool get hasStrengths =>
      xt != null && xc != null && yt != null && yc != null && s12 != null;

  /// One-line summary in the given units, e.g. "E1 181 GPa · E2 10.3 GPa".
  String summary(Units units) {
    String mod(double v) => _short(units.modulusFromGPa(v));
    final parts = <String>[
      if (kind == MaterialKind.matrix) ...[
        'E ${mod(e1)} ${units.modulus}',
        'ν ${_short(nu12)}',
      ] else ...[
        'E1 ${mod(e1)} ${units.modulus}',
        if (e2 != null) 'E2 ${mod(e2!)} ${units.modulus}',
        if (g12 != null) 'G12 ${mod(g12!)} ${units.modulus}',
        'ν12 ${_short(nu12)}',
      ],
      if (hasStrengths) 'Xt ${_short(units.stressFromMPa(xt!))} ${units.stress}',
    ];
    return parts.join(' · ');
  }

  static String _short(double value) {
    final text = double.parse(value.toStringAsPrecision(4)).toString();
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  void applyToLamina(TransverselyIsotropicMaterial target, Units units) {
    target
      ..e1 = units.modulusFromGPa(e1)
      ..e2 = e2 == null ? target.e2 : units.modulusFromGPa(e2!)
      ..g12 = g12 == null ? target.g12 : units.modulusFromGPa(g12!)
      ..nu12 = nu12
      ..nu23 = nu23 ?? target.nu23;
  }

  void applyToIsotropic(IsotropicMaterial target, Units units) {
    target
      ..e = units.modulusFromGPa(e1)
      ..nu = nu12;
  }

  void applyCte(TransverselyIsotropicCTE target, Units units) {
    if (!hasCte) return;
    target
      ..alpha11 = units.cteFromPerC(alpha11!)
      ..alpha22 = units.cteFromPerC(alpha22 ?? alpha11!)
      ..alpha12 = 0;
  }

  void applyIsotropicCte(IsotropicCTE target, Units units) {
    if (!hasCte) return;
    target.alpha = units.cteFromPerC(alpha11!);
  }

  void applyStrengths(LaminaStrengths target, Units units) {
    if (!hasStrengths) return;
    target
      ..xt = units.stressFromMPa(xt!)
      ..xc = units.stressFromMPa(xc!)
      ..yt = units.stressFromMPa(yt!)
      ..yc = units.stressFromMPa(yc!)
      ..s12 = units.stressFromMPa(s12!);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'source': source,
        'e1': e1,
        'e2': e2,
        'g12': g12,
        'nu12': nu12,
        'nu23': nu23,
        'alpha11': alpha11,
        'alpha22': alpha22,
        'xt': xt,
        'xc': xc,
        'yt': yt,
        'yc': yc,
        's12': s12,
      };

  static LibraryMaterial? fromJson(Map<String, dynamic> json) {
    double? number(String key) => (json[key] as num?)?.toDouble();
    final e1 = number('e1');
    final nu12 = number('nu12');
    final name = json['name'] as String?;
    if (e1 == null || nu12 == null || name == null) return null;
    return LibraryMaterial(
      id: json['id'] as String? ?? name,
      name: name,
      kind: MaterialKind.values.firstWhere(
        (kind) => kind.name == json['kind'],
        orElse: () => MaterialKind.lamina,
      ),
      source: json['source'] as String? ?? '',
      isCustom: true,
      e1: e1,
      e2: number('e2'),
      g12: number('g12'),
      nu12: nu12,
      nu23: number('nu23'),
      alpha11: number('alpha11'),
      alpha22: number('alpha22'),
      xt: number('xt'),
      xc: number('xc'),
      yt: number('yt'),
      yc: number('yc'),
      s12: number('s12'),
    );
  }

  /// Builds a custom entry from calculator inputs given in [units].
  /// Returns null when the required elastic constants are missing.
  static LibraryMaterial? fromLaminaInputs({
    required String name,
    required Units units,
    required TransverselyIsotropicMaterial material,
    TransverselyIsotropicCTE? cte,
    LaminaStrengths? strengths,
    MaterialKind kind = MaterialKind.lamina,
  }) {
    if (material.e1 == null || material.nu12 == null) return null;
    double? mod(double? v) => v == null ? null : units.modulusToGPa(v);
    double? str(double? v) => v == null ? null : units.stressToMPa(v);
    double? exp(double? v) => v == null ? null : units.cteToPerC(v);
    final hasStrengths = strengths?.isValid() ?? false;
    return LibraryMaterial(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      kind: kind,
      source: 'Saved from calculator inputs',
      isCustom: true,
      e1: mod(material.e1)!,
      e2: mod(material.e2),
      g12: mod(material.g12),
      nu12: material.nu12!,
      nu23: material.nu23,
      alpha11: exp(cte?.alpha11),
      alpha22: exp(cte?.alpha22),
      xt: hasStrengths ? str(strengths!.xt) : null,
      xc: hasStrengths ? str(strengths!.xc) : null,
      yt: hasStrengths ? str(strengths!.yt) : null,
      yc: hasStrengths ? str(strengths!.yc) : null,
      s12: hasStrengths ? str(strengths!.s12) : null,
    );
  }

  static LibraryMaterial? fromIsotropicInputs({
    required String name,
    required Units units,
    required IsotropicMaterial material,
    IsotropicCTE? cte,
  }) {
    if (material.e == null || material.nu == null) return null;
    return LibraryMaterial(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      kind: MaterialKind.matrix,
      source: 'Saved from calculator inputs',
      isCustom: true,
      e1: units.modulusToGPa(material.e!),
      nu12: material.nu!,
      alpha11: cte?.alpha == null ? null : units.cteToPerC(cte!.alpha!),
    );
  }
}

/// Built-in materials plus the user's saved materials.
class MaterialLibrary extends ChangeNotifier {
  MaterialLibrary._();

  static final MaterialLibrary instance = MaterialLibrary._();

  static const String _storageKey = 'Custom_Materials_v1';

  List<LibraryMaterial>? _custom;

  List<LibraryMaterial> get customMaterials =>
      List.unmodifiable(_custom ??= _load());

  List<LibraryMaterial> materials(MaterialKind kind) => [
        ...customMaterials.where((material) => material.kind == kind),
        ...builtInMaterials.where((material) => material.kind == kind),
      ];

  Future<void> save(LibraryMaterial material) async {
    final custom = [..._custom ??= _load()];
    custom.removeWhere(
      (existing) =>
          existing.kind == material.kind &&
          existing.name.toLowerCase() == material.name.toLowerCase(),
    );
    custom.insert(0, material);
    _custom = custom;
    await _persist();
    notifyListeners();
  }

  Future<void> remove(LibraryMaterial material) async {
    final custom = [..._custom ??= _load()]
      ..removeWhere((existing) => existing.id == material.id);
    _custom = custom;
    await _persist();
    notifyListeners();
  }

  List<LibraryMaterial> _load() {
    try {
      final raw = SharedPreferencesHelper.localStorage.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LibraryMaterial.fromJson)
          .whereType<LibraryMaterial>()
          .toList();
    } catch (error) {
      if (kDebugMode) debugPrint('Failed to load custom materials: $error');
      return [];
    }
  }

  Future<void> _persist() async {
    await SharedPreferencesHelper.localStorage.setString(
      _storageKey,
      jsonEncode(_custom!.map((material) => material.toJson()).toList()),
    );
  }

  @visibleForTesting
  void resetForTest() => _custom = null;
}

/// Typical published properties for preliminary design. Values vary with
/// fiber volume fraction, cure cycle and supplier; verify against data sheets
/// before relying on them.
const List<LibraryMaterial> builtInMaterials = [
  // Unidirectional laminae.
  LibraryMaterial(
    id: 't300-5208',
    name: 'T300/5208 carbon/epoxy',
    kind: MaterialKind.lamina,
    source: 'Kaw, Mechanics of Composite Materials (2006), Table 2.1',
    e1: 181,
    e2: 10.3,
    g12: 7.17,
    nu12: 0.28,
    alpha11: 0.02e-6,
    alpha22: 22.5e-6,
    xt: 1500,
    xc: 1500,
    yt: 40,
    yc: 246,
    s12: 68,
  ),
  LibraryMaterial(
    id: 'as4-3501-6',
    name: 'AS4/3501-6 carbon/epoxy',
    kind: MaterialKind.lamina,
    source: 'Soden, Hinton & Kaddour, World-Wide Failure Exercise (1998)',
    e1: 126,
    e2: 11,
    g12: 6.6,
    nu12: 0.28,
    nu23: 0.4,
    alpha11: -1e-6,
    alpha22: 26e-6,
    xt: 1950,
    xc: 1480,
    yt: 48,
    yc: 200,
    s12: 79,
  ),
  LibraryMaterial(
    id: 't300-914c',
    name: 'T300/BSL914C carbon/epoxy',
    kind: MaterialKind.lamina,
    source: 'Soden, Hinton & Kaddour, World-Wide Failure Exercise (1998)',
    e1: 138,
    e2: 11,
    g12: 5.5,
    nu12: 0.28,
    nu23: 0.4,
    alpha11: -1e-6,
    alpha22: 26e-6,
    xt: 1500,
    xc: 900,
    yt: 27,
    yc: 200,
    s12: 80,
  ),
  LibraryMaterial(
    id: 'im7-8552',
    name: 'IM7/8552 carbon/epoxy',
    kind: MaterialKind.lamina,
    source: 'Camanho et al., IM7/8552 characterization data',
    e1: 171.42,
    e2: 9.08,
    g12: 5.29,
    nu12: 0.32,
    alpha11: -5.5e-6,
    alpha22: 25.8e-6,
    xt: 2323.5,
    xc: 1200.1,
    yt: 62.3,
    yc: 199.8,
    s12: 92.3,
  ),
  LibraryMaterial(
    id: 'eglass-ly556',
    name: 'E-glass/LY556 epoxy',
    kind: MaterialKind.lamina,
    source: 'Soden, Hinton & Kaddour, World-Wide Failure Exercise (1998)',
    e1: 53.48,
    e2: 17.7,
    g12: 5.83,
    nu12: 0.278,
    nu23: 0.4,
    alpha11: 8.6e-6,
    alpha22: 26.4e-6,
    xt: 1140,
    xc: 570,
    yt: 35,
    yc: 114,
    s12: 72,
  ),
  LibraryMaterial(
    id: 'scotchply-1002',
    name: 'E-glass/epoxy (Scotchply 1002)',
    kind: MaterialKind.lamina,
    source: 'Kaw, Mechanics of Composite Materials (2006), Table 2.1',
    e1: 38.6,
    e2: 8.27,
    g12: 4.14,
    nu12: 0.26,
    alpha11: 8.6e-6,
    alpha22: 22.1e-6,
    xt: 1062,
    xc: 610,
    yt: 31,
    yc: 118,
    s12: 72,
  ),
  LibraryMaterial(
    id: 'boron-5505',
    name: 'Boron/5505 epoxy',
    kind: MaterialKind.lamina,
    source: 'Kaw, Mechanics of Composite Materials (2006), Table 2.1',
    e1: 204,
    e2: 18.5,
    g12: 5.59,
    nu12: 0.23,
    alpha11: 6.1e-6,
    alpha22: 30.3e-6,
    xt: 1260,
    xc: 2500,
    yt: 61,
    yc: 202,
    s12: 67,
  ),
  LibraryMaterial(
    id: 'kevlar49-epoxy',
    name: 'Kevlar 49/epoxy',
    kind: MaterialKind.lamina,
    source: 'Daniel & Ishai, Engineering Mechanics of Composite Materials',
    e1: 80,
    e2: 5.5,
    g12: 2.2,
    nu12: 0.34,
    alpha11: -2e-6,
    alpha22: 60e-6,
    xt: 1400,
    xc: 335,
    yt: 30,
    yc: 158,
    s12: 49,
  ),
  // Fibers.
  LibraryMaterial(
    id: 'fiber-as4',
    name: 'AS4 carbon fiber',
    kind: MaterialKind.fiber,
    source: 'Soden, Hinton & Kaddour, World-Wide Failure Exercise (1998)',
    e1: 225,
    e2: 15,
    g12: 15,
    nu12: 0.2,
    nu23: 0.07,
    alpha11: -0.5e-6,
    alpha22: 15e-6,
  ),
  LibraryMaterial(
    id: 'fiber-t300',
    name: 'T300 carbon fiber',
    kind: MaterialKind.fiber,
    source: 'Soden, Hinton & Kaddour, World-Wide Failure Exercise (1998)',
    e1: 230,
    e2: 15,
    g12: 15,
    nu12: 0.2,
    nu23: 0.07,
    alpha11: -0.7e-6,
    alpha22: 12e-6,
  ),
  LibraryMaterial(
    id: 'fiber-eglass',
    name: 'E-glass fiber (Gevetex)',
    kind: MaterialKind.fiber,
    source: 'Soden, Hinton & Kaddour, World-Wide Failure Exercise (1998)',
    e1: 80,
    e2: 80,
    g12: 33.33,
    nu12: 0.2,
    nu23: 0.2,
    alpha11: 4.9e-6,
    alpha22: 4.9e-6,
  ),
  // Matrices.
  LibraryMaterial(
    id: 'matrix-3501-6',
    name: '3501-6 epoxy',
    kind: MaterialKind.matrix,
    source: 'Soden, Hinton & Kaddour, World-Wide Failure Exercise (1998)',
    e1: 4.2,
    nu12: 0.34,
    alpha11: 45e-6,
  ),
  LibraryMaterial(
    id: 'matrix-914c',
    name: 'BSL914C epoxy',
    kind: MaterialKind.matrix,
    source: 'Soden, Hinton & Kaddour, World-Wide Failure Exercise (1998)',
    e1: 4.0,
    nu12: 0.35,
    alpha11: 55e-6,
  ),
  LibraryMaterial(
    id: 'matrix-ly556',
    name: 'LY556/HT907/DY063 epoxy',
    kind: MaterialKind.matrix,
    source: 'Soden, Hinton & Kaddour, World-Wide Failure Exercise (1998)',
    e1: 3.35,
    nu12: 0.35,
    alpha11: 58e-6,
  ),
];
