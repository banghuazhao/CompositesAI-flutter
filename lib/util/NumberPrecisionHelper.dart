import 'package:flutter/foundation.dart';

import 'others.dart';
import 'result_precision.dart';

class NumberPrecisionHelper extends ChangeNotifier {
  final String KEY = "Number_Precision";
  int? _selectedPrecision;

  int get precision {
    final selected = _selectedPrecision;
    if (selected != null) return selected;
    try {
      final stored = SharedPreferencesHelper.localStorage.get(KEY);
      return stored is int
          ? ResultPrecision.normalize(stored)
          : ResultPrecision.defaultValue;
    } catch (_) {
      return ResultPrecision.defaultValue;
    }
  }

  Future<void> set(int precision) async {
    final normalized = ResultPrecision.normalize(precision);
    final previous = this.precision;
    _selectedPrecision = normalized;
    if (normalized != previous) notifyListeners();
    try {
      await SharedPreferencesHelper.localStorage.setInt(KEY, normalized);
    } catch (_) {
      // Keep the valid session preference if storage is unavailable or fails.
    }
  }
}
