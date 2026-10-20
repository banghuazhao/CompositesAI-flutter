class LayupAngle {
  double? value;

  bool isValid() => value?.isFinite ?? false;
}
