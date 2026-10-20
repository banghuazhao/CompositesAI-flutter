class DeltaTemperature {
  double? value;

  bool isValid() => value?.isFinite ?? false;
}
