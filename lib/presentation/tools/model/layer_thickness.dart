import 'package:flutter/foundation.dart';

class LayerThickness extends ChangeNotifier {
  double? _value;

  double? get value => _value;

  set value(double? value) {
    if (_value == value || (_value?.isNaN == true && value?.isNaN == true)) {
      return;
    }
    _value = value;
    notifyListeners();
  }

  bool isValid() => _value != null && _value!.isFinite && _value! > 0;
}
