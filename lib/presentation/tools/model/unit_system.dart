import 'package:flutter/foundation.dart';

import '../../../util/others.dart';

/// Unit systems for the composite calculators.
///
/// Moduli are entered in GPa (SI) or Msi (US), and stresses, strengths and
/// loads in MPa-mm or ksi-in. In both systems the stress unit is exactly 1/1000
/// of the modulus unit, so a single factor ([modulusToStress]) converts moduli
/// into the stress unit before any calculation that mixes the two. Everything
/// downstream then stays consistent: A in N/mm (kip/in), B in N (kip), D in
/// N·mm (kip·in).
enum UnitSystem { si, us }

/// Unit symbols for one [UnitSystem].
class Units {
  const Units._(this.system);

  factory Units.of(UnitSystem system) =>
      system == UnitSystem.si ? si : us;

  static const Units si = Units._(UnitSystem.si);
  static const Units us = Units._(UnitSystem.us);

  /// Multiply a modulus by this to express it in the stress unit.
  static const double modulusToStress = 1000;

  final UnitSystem system;

  bool get isSI => system == UnitSystem.si;

  String get name => isSI ? 'SI' : 'US customary';
  String get summary => isSI ? 'GPa · MPa · mm' : 'Msi · ksi · in';

  String get modulus => isSI ? 'GPa' : 'Msi';
  String get stress => isSI ? 'MPa' : 'ksi';
  String get length => isSI ? 'mm' : 'in';
  String get temperature => isSI ? '°C' : '°F';
  String get cte => isSI ? '1/°C' : '1/°F';

  /// Force per unit width (stress × length).
  String get forceResultant => isSI ? 'N/mm' : 'kip/in';

  /// Moment per unit width (stress × length²).
  String get momentResultant => isSI ? 'N·mm/mm' : 'kip·in/in';

  /// Curvature.
  String get curvature => isSI ? '1/mm' : '1/in';

  String get aMatrix => isSI ? 'N/mm' : 'kip/in';
  String get bMatrix => isSI ? 'N' : 'kip';
  String get dMatrix => isSI ? 'N·mm' : 'kip·in';
  String get compliance => isSI ? '1/GPa' : '1/Msi';
  String get stressCompliance => isSI ? '1/MPa' : '1/ksi';

  /// A modulus above this is almost certainly entered in the wrong unit
  /// (e.g. 150000 typed for E1 in GPa).
  double get maxPlausibleModulus => isSI ? 1500 : 220;

  // Conversions from SI (GPa, MPa, mm, 1/°C) into this system.
  static const double _gpaPerMsi = 6.894757293168361;
  static const double _mpaPerKsi = 6.894757293168361;

  double modulusFromGPa(double gpa) => isSI ? gpa : gpa / _gpaPerMsi;
  double stressFromMPa(double mpa) => isSI ? mpa : mpa / _mpaPerKsi;
  double lengthFromMm(double mm) => isSI ? mm : mm / 25.4;
  double cteFromPerC(double perC) => isSI ? perC : perC / 1.8;

  double modulusToGPa(double value) => isSI ? value : value * _gpaPerMsi;
  double stressToMPa(double value) => isSI ? value : value * _mpaPerKsi;
  double cteToPerC(double value) => isSI ? value : value * 1.8;
}

/// Persists the selected unit system and notifies listeners on change.
class UnitSettings extends ChangeNotifier {
  static const String _key = 'Calculator_Unit_System';

  UnitSystem get system {
    try {
      final stored = SharedPreferencesHelper.localStorage.getString(_key);
      return stored == UnitSystem.us.name ? UnitSystem.us : UnitSystem.si;
    } catch (_) {
      return UnitSystem.si;
    }
  }

  Units get units => Units.of(system);

  Future<void> setSystem(UnitSystem system) async {
    if (system == this.system) return;
    await SharedPreferencesHelper.localStorage.setString(_key, system.name);
    notifyListeners();
  }
}

/// Appends a unit to a field label: `E1 (GPa)`.
String withUnit(String label, String unit) =>
    unit.isEmpty ? label : '$label ($unit)';
