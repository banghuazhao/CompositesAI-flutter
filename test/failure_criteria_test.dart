import 'dart:math' as math;

import 'package:composite_calculator/composite_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swiftcomp/presentation/tools/model/failure_criteria.dart';

void main() {
  // T300/5208 (Kaw, Table 2.1) in MPa.
  LaminaStrengths t300() =>
      LaminaStrengths(xt: 1500, xc: 1500, yt: 40, yc: 246, s12: 68);

  group('FailureCriteria', () {
    test('uniaxial fiber tension at half strength gives R = 2', () {
      for (final criterion in FailureCriterion.values) {
        final result =
            FailureCriteria.evaluate(criterion, 750, 0, 0, t300());
        expect(result.strengthRatio, closeTo(2, 1e-9), reason: criterion.label);
        expect(result.mode, 'Fiber tension', reason: criterion.label);
      }
    });

    test('transverse tension at half strength gives R = 2', () {
      for (final criterion in FailureCriterion.values) {
        final result = FailureCriteria.evaluate(criterion, 0, 20, 0, t300());
        expect(result.strengthRatio, closeTo(2, 1e-9), reason: criterion.label);
        expect(result.mode, 'Matrix tension', reason: criterion.label);
      }
    });

    test('transverse compression uses Yc', () {
      final result = FailureCriteria.maxStress(0, -123, 0, t300());
      expect(result.strengthRatio, closeTo(2, 1e-9));
      expect(result.mode, 'Matrix compression');
    });

    test('pure shear at strength fails every criterion exactly', () {
      for (final criterion in FailureCriterion.values) {
        final result = FailureCriteria.evaluate(criterion, 0, 0, 68, t300());
        expect(result.failureIndex, closeTo(1, 1e-9), reason: criterion.label);
      }
    });

    test('Tsai-Hill combines stress components', () {
      // (σ1/X)² − σ1σ2/X² + (σ2/Y)² + (τ/S)² with σ1 = 500, σ2 = 10, τ = 20.
      const index = 1 / 9 - 500 * 10 / (1500 * 1500) + 1 / 16 + 400 / 4624;
      final result = FailureCriteria.tsaiHill(500, 10, 20, t300());
      expect(result.failureIndex, closeTo(math.sqrt(index), 1e-9));
    });

    test('Tsai-Wu strength ratio solves the quadratic', () {
      final s = t300();
      final result = FailureCriteria.tsaiWu(300, -50, 30, s);
      final r = result.strengthRatio;
      final f1 = 1 / s.xt! - 1 / s.xc!;
      final f2 = 1 / s.yt! - 1 / s.yc!;
      final f11 = 1 / (s.xt! * s.xc!);
      final f22 = 1 / (s.yt! * s.yc!);
      final f66 = 1 / (s.s12! * s.s12!);
      final f12 = -0.5 * math.sqrt(f11 * f22);
      double at(double k) {
        final s1 = 300 * k, s2 = -50 * k, t = 30 * k;
        return f1 * s1 +
            f2 * s2 +
            f11 * s1 * s1 +
            f22 * s2 * s2 +
            f66 * t * t +
            2 * f12 * s1 * s2;
      }

      expect(at(r), closeTo(1, 1e-9));
    });

    test('unloaded point has zero failure index', () {
      final result = FailureCriteria.hashin(0, 0, 0, t300());
      expect(result.strengthRatio, double.infinity);
      expect(result.failureIndex, 0);
      expect(result.fails, isFalse);
    });
  });

  group('LaminateFailureAnalysis', () {
    LaminateFailureResult analyze(
      List<double> layup, {
      List<double> forces = const [0, 0, 0],
      List<double> moments = const [0, 0, 0],
    }) {
      return LaminateFailureAnalysis.analyze(
        e1: 181000,
        e2: 10300,
        g12: 7170,
        nu12: 0.28,
        layup: layup,
        plyThickness: 0.125,
        forces: forces,
        moments: moments,
        strengths: t300(),
      );
    }

    test('unidirectional laminate under Nx carries σ1 = Nx / h', () {
      // Four 0° plies, h = 0.5 mm; Nx = 375 N/mm gives σ1 = 750 MPa.
      final result = analyze([0, 0, 0, 0], forces: [375, 0, 0]);
      for (final point in result.points) {
        expect(point.materialStress[0], closeTo(750, 1e-6));
        expect(point.materialStress[1], closeTo(0, 1e-6));
        expect(point.materialStress[2], 0);
      }
      expect(
        result.firstPlyFailureFactor(FailureCriterion.maxStress),
        closeTo(2, 1e-9),
      );
    });

    test('cross-ply laminate fails first in the 90° plies', () {
      final result = analyze([0, 90, 90, 0], forces: [100, 0, 0]);
      for (final criterion in FailureCriterion.values) {
        final critical = result.critical(criterion);
        expect(critical.angle, 90, reason: criterion.label);
        expect(critical.results[criterion]!.mode, 'Matrix tension');
      }
    });

    test('round-off shear in a cross-ply under tension is reported as zero',
        () {
      final result = analyze([0, 90, 90, 0], forces: [100, 0, 0]);
      for (final point in result.points) {
        expect(point.materialStress[2], 0);
      }
    });

    test('bending puts opposite surfaces in tension and compression', () {
      final result = analyze([0, 0, 0, 0], moments: [10, 0, 0]);
      final bottom = result.points.first;
      final top = result.points.last;
      expect(bottom.isTop, isFalse);
      expect(top.isTop, isTrue);
      expect(bottom.materialStress[0], closeTo(-top.materialStress[0], 1e-6));
      expect(bottom.materialStress[0].sign, isNot(top.materialStress[0].sign));
    });

    test('midplane response matches the laminate stress-strain calculator',
        () {
      const layup = [0.0, 45.0, -45.0, 90.0, 90.0, -45.0, 45.0, 0.0];
      final result = analyze(layup, forces: [50, -20, 10], moments: [2, 1, 0]);
      final reference = LaminarStressStrainCalculator.calculate(
        LaminarStressStrainInput(
          E1: 181000,
          E2: 10300,
          G12: 7170,
          nu12: 0.28,
          layupSequence: '[0/45/-45/90]s',
          layerThickness: 0.125,
          N11: 50,
          N22: -20,
          N12: 10,
          M11: 2,
          M22: 1,
        ),
      );
      expect(result.midplaneStrains[0], closeTo(reference.epsilon11, 1e-12));
      expect(result.midplaneStrains[1], closeTo(reference.epsilon22, 1e-12));
      expect(result.midplaneStrains[2], closeTo(reference.epsilon12, 1e-12));
      expect(result.curvatures[0], closeTo(reference.kappa11, 1e-12));
      expect(result.curvatures[1], closeTo(reference.kappa22, 1e-12));
      expect(result.curvatures[2], closeTo(reference.kappa12, 1e-12));
    });
  });
}
