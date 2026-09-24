import 'dart:math' as math;

import 'package:linalg/matrix.dart';

/// Lamina strengths, all positive magnitudes in the calculator stress unit.
class LaminaStrengths {
  LaminaStrengths({this.xt, this.xc, this.yt, this.yc, this.s12});

  /// Longitudinal tensile / compressive strength.
  double? xt;
  double? xc;

  /// Transverse tensile / compressive strength.
  double? yt;
  double? yc;

  /// In-plane shear strength.
  double? s12;

  bool isValid() =>
      [xt, xc, yt, yc, s12].every((value) => value != null && value > 0);
}

enum FailureCriterion { maxStress, tsaiHill, tsaiWu, hashin }

extension FailureCriterionLabel on FailureCriterion {
  String get label => switch (this) {
        FailureCriterion.maxStress => 'Maximum stress',
        FailureCriterion.tsaiHill => 'Tsai-Hill',
        FailureCriterion.tsaiWu => 'Tsai-Wu',
        FailureCriterion.hashin => 'Hashin',
      };

  String get shortLabel => switch (this) {
        FailureCriterion.maxStress => 'Max σ',
        FailureCriterion.tsaiHill => 'Tsai-Hill',
        FailureCriterion.tsaiWu => 'Tsai-Wu',
        FailureCriterion.hashin => 'Hashin',
      };
}

/// Outcome of one criterion at one point.
class CriterionResult {
  const CriterionResult(this.strengthRatio, this.mode);

  /// Load multiplier that brings this point to failure. Values below 1 mean
  /// the applied load already exceeds the criterion. Infinite when unloaded.
  final double strengthRatio;

  /// Governing failure mode, e.g. "Matrix tension".
  final String mode;

  /// 1 / strength ratio, so values of 1 or more indicate failure.
  double get failureIndex =>
      strengthRatio.isInfinite ? 0 : 1 / strengthRatio;

  bool get fails => failureIndex >= 1;
}

/// Plane-stress lamina failure criteria. Stresses are in material axes
/// (1 = fiber direction) and share the unit of the strengths.
class FailureCriteria {
  const FailureCriteria._();

  static const CriterionResult _unloaded = CriterionResult(
    double.infinity,
    'Unloaded',
  );

  static CriterionResult evaluate(
    FailureCriterion criterion,
    double s1,
    double s2,
    double t12,
    LaminaStrengths strengths,
  ) {
    return switch (criterion) {
      FailureCriterion.maxStress => maxStress(s1, s2, t12, strengths),
      FailureCriterion.tsaiHill => tsaiHill(s1, s2, t12, strengths),
      FailureCriterion.tsaiWu => tsaiWu(s1, s2, t12, strengths),
      FailureCriterion.hashin => hashin(s1, s2, t12, strengths),
    };
  }

  static CriterionResult maxStress(
    double s1,
    double s2,
    double t12,
    LaminaStrengths s,
  ) {
    final ratios = <String, double>{
      s1 >= 0 ? 'Fiber tension' : 'Fiber compression':
          s1.abs() / (s1 >= 0 ? s.xt! : s.xc!),
      s2 >= 0 ? 'Matrix tension' : 'Matrix compression':
          s2.abs() / (s2 >= 0 ? s.yt! : s.yc!),
      'In-plane shear': t12.abs() / s.s12!,
    };
    final governing =
        ratios.entries.reduce((a, b) => b.value > a.value ? b : a);
    if (governing.value == 0) return _unloaded;
    return CriterionResult(1 / governing.value, governing.key);
  }

  /// Tsai-Hill with tensile or compressive strengths chosen by stress sign.
  static CriterionResult tsaiHill(
    double s1,
    double s2,
    double t12,
    LaminaStrengths s,
  ) {
    final x = s1 >= 0 ? s.xt! : s.xc!;
    final y = s2 >= 0 ? s.yt! : s.yc!;
    final fiber = math.pow(s1 / x, 2).toDouble();
    final matrix = math.pow(s2 / y, 2).toDouble();
    final shear = math.pow(t12 / s.s12!, 2).toDouble();
    final index = fiber - s1 * s2 / (x * x) + matrix + shear;
    if (index <= 0) return _unloaded;
    return CriterionResult(1 / math.sqrt(index), _dominant(s1, s2, fiber, matrix, shear));
  }

  /// Tsai-Wu with the common interaction estimate F12 = -½√(F11·F22).
  static CriterionResult tsaiWu(
    double s1,
    double s2,
    double t12,
    LaminaStrengths s,
  ) {
    final f1 = 1 / s.xt! - 1 / s.xc!;
    final f2 = 1 / s.yt! - 1 / s.yc!;
    final f11 = 1 / (s.xt! * s.xc!);
    final f22 = 1 / (s.yt! * s.yc!);
    final f66 = 1 / (s.s12! * s.s12!);
    final f12 = -0.5 * math.sqrt(f11 * f22);

    // Scaling stresses by R gives a·R² + b·R − 1 = 0.
    final a = f11 * s1 * s1 + f22 * s2 * s2 + f66 * t12 * t12 + 2 * f12 * s1 * s2;
    final b = f1 * s1 + f2 * s2;
    final ratio = _positiveRoot(a, b);
    if (ratio == null) return _unloaded;
    return CriterionResult(
      ratio,
      _dominant(
        s1,
        s2,
        f11 * s1 * s1 + (f1 * s1).abs(),
        f22 * s2 * s2 + (f2 * s2).abs(),
        f66 * t12 * t12,
      ),
    );
  }

  /// Hashin (1980) plane-stress criteria. The transverse shear strength is
  /// taken as Yc/2, which reduces matrix compression to (σ2/Yc)² + (τ12/S12)².
  static CriterionResult hashin(
    double s1,
    double s2,
    double t12,
    LaminaStrengths s,
  ) {
    final shear = math.pow(t12 / s.s12!, 2).toDouble();
    final fiberIndex = s1 >= 0
        ? math.pow(s1 / s.xt!, 2).toDouble() + shear
        : math.pow(s1 / s.xc!, 2).toDouble();
    final matrixIndex = s2 >= 0
        ? math.pow(s2 / s.yt!, 2).toDouble() + shear
        : math.pow(s2 / s.yc!, 2).toDouble() + shear;

    final fiberGoverns = fiberIndex >= matrixIndex;
    final index = fiberGoverns ? fiberIndex : matrixIndex;
    if (index <= 0) return _unloaded;
    final mode = fiberGoverns
        ? (s1 >= 0 ? 'Fiber tension' : 'Fiber compression')
        : (s2 >= 0 ? 'Matrix tension' : 'Matrix compression');
    return CriterionResult(1 / math.sqrt(index), mode);
  }

  static double? _positiveRoot(double a, double b) {
    const epsilon = 1e-30;
    if (a.abs() < epsilon) {
      return b > epsilon ? 1 / b : null;
    }
    final discriminant = b * b + 4 * a;
    if (discriminant < 0) return null;
    final root = (-b + math.sqrt(discriminant)) / (2 * a);
    return root > 0 ? root : null;
  }

  static String _dominant(
    double s1,
    double s2,
    double fiber,
    double matrix,
    double shear,
  ) {
    if (fiber >= matrix && fiber >= shear) {
      return s1 >= 0 ? 'Fiber tension' : 'Fiber compression';
    }
    if (matrix >= shear) {
      return s2 >= 0 ? 'Matrix tension' : 'Matrix compression';
    }
    return 'In-plane shear';
  }
}

/// Stresses and criterion results at the top or bottom surface of a ply.
class PlyStressPoint {
  PlyStressPoint({
    required this.ply,
    required this.angle,
    required this.isTop,
    required this.z,
    required this.globalStress,
    required this.materialStress,
    required this.results,
  });

  /// 1-based ply number, counted from the bottom (most negative z).
  final int ply;
  final double angle;
  final bool isTop;
  final double z;

  /// σx, σy, τxy.
  final List<double> globalStress;

  /// σ1, σ2, τ12.
  final List<double> materialStress;

  final Map<FailureCriterion, CriterionResult> results;

  String get position => isTop ? 'Top' : 'Bottom';
}

class LaminateFailureResult {
  LaminateFailureResult({
    required this.points,
    required this.midplaneStrains,
    required this.curvatures,
  });

  final List<PlyStressPoint> points;

  /// ε0x, ε0y, γ0xy.
  final List<double> midplaneStrains;

  /// κx, κy, κxy.
  final List<double> curvatures;

  /// The point with the lowest strength ratio for [criterion].
  PlyStressPoint critical(FailureCriterion criterion) {
    return points.reduce((a, b) {
      return b.results[criterion]!.strengthRatio <
              a.results[criterion]!.strengthRatio
          ? b
          : a;
    });
  }

  /// First-ply failure load factor for [criterion].
  double firstPlyFailureFactor(FailureCriterion criterion) =>
      critical(criterion).results[criterion]!.strengthRatio;
}

/// Classical lamination theory stress analysis followed by ply-by-ply failure
/// evaluation. Moduli, strengths and loads must share one consistent unit set
/// (e.g. MPa, mm, N/mm, N·mm/mm). Mechanical loads only.
class LaminateFailureAnalysis {
  const LaminateFailureAnalysis._();

  static LaminateFailureResult analyze({
    required double e1,
    required double e2,
    required double g12,
    required double nu12,
    required List<double> layup,
    required double plyThickness,
    required List<double> forces,
    required List<double> moments,
    required LaminaStrengths strengths,
  }) {
    final plyCount = layup.length;
    final totalThickness = plyCount * plyThickness;
    final nu21 = nu12 * e2 / e1;
    final denominator = 1 - nu12 * nu21;
    final q = Matrix([
      [e1 / denominator, nu12 * e2 / denominator, 0],
      [nu12 * e2 / denominator, e2 / denominator, 0],
      [0, 0, g12],
    ]);

    final qBars = <Matrix>[];
    var a = Matrix.fill(3, 3);
    var b = Matrix.fill(3, 3);
    var d = Matrix.fill(3, 3);
    for (var k = 0; k < plyCount; k++) {
      final bottom = -totalThickness / 2 + k * plyThickness;
      final top = bottom + plyThickness;
      final rotation = _globalFromMaterial(layup[k]);
      final qBar = rotation * q * rotation.transpose();
      qBars.add(qBar);
      a += qBar * (top - bottom);
      b += qBar * ((top * top - bottom * bottom) / 2);
      d += qBar * ((top * top * top - bottom * bottom * bottom) / 3);
    }

    final abd = Matrix([
      for (var i = 0; i < 3; i++) [...a[i], ...b[i]],
      for (var i = 0; i < 3; i++) [...b[i], ...d[i]],
    ]);
    final loads = Matrix([
      for (final value in [...forces, ...moments]) [value],
    ]);
    final response = abd.inverse() * loads;
    final strains = [for (var i = 0; i < 3; i++) response[i][0]];
    final curvatures = [for (var i = 3; i < 6; i++) response[i][0]];

    // Stresses are evaluated first so round-off (e.g. τ12 ≈ 1e-15 in a
    // cross-ply under pure tension) can be cleaned relative to the peak.
    final evaluated = <(int, bool, double, List<double>, List<double>)>[];
    for (var k = 0; k < plyCount; k++) {
      final bottom = -totalThickness / 2 + k * plyThickness;
      for (final isTop in [false, true]) {
        final z = isTop ? bottom + plyThickness : bottom;
        final strain = Matrix([
          for (var i = 0; i < 3; i++) [strains[i] + z * curvatures[i]],
        ]);
        final global = qBars[k] * strain;
        final material = _materialFromGlobal(layup[k]) * global;
        evaluated.add((
          k,
          isTop,
          z,
          [for (var i = 0; i < 3; i++) global[i][0]],
          [for (var i = 0; i < 3; i++) material[i][0]],
        ));
      }
    }

    final peak = evaluated
        .expand((point) => [...point.$4, ...point.$5])
        .fold<double>(0, (max, value) => math.max(max, value.abs()));
    double clean(double value) => value.abs() <= peak * 1e-12 ? 0 : value;

    final points = <PlyStressPoint>[
      for (final (k, isTop, z, global, material) in evaluated)
        () {
          final stresses = [for (final value in material) clean(value)];
          return PlyStressPoint(
            ply: k + 1,
            angle: layup[k],
            isTop: isTop,
            z: z,
            globalStress: [for (final value in global) clean(value)],
            materialStress: stresses,
            results: {
              for (final criterion in FailureCriterion.values)
                criterion: FailureCriteria.evaluate(
                  criterion,
                  stresses[0],
                  stresses[1],
                  stresses[2],
                  strengths,
                ),
            },
          );
        }(),
    ];

    return LaminateFailureResult(
      points: points,
      midplaneStrains: strains,
      curvatures: curvatures,
    );
  }

  /// Stress transformation from material to laminate axes for a ply at
  /// [angleDegrees]; matches the composite_calculator convention.
  static Matrix _globalFromMaterial(double angleDegrees) {
    final radians = angleDegrees * math.pi / 180;
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Matrix([
      [c * c, s * s, -2 * s * c],
      [s * s, c * c, 2 * s * c],
      [s * c, -s * c, c * c - s * s],
    ]);
  }

  static Matrix _materialFromGlobal(double angleDegrees) =>
      _globalFromMaterial(-angleDegrees);
}
