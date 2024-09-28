class VolumeFraction {
  double? value;

  isValid() {
    if (value != null) {
      if (value! >= 0 && value! <= 1) {
        return true;
      }
    }
    return false;
  }
}
