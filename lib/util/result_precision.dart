/// Supported decimal places in the calculator's scientific notation.
class ResultPrecision {
  const ResultPrecision._();

  static const int minimum = 1;
  static const int maximum = 9;
  static const int defaultValue = 5;

  static int normalize(int value) => value.clamp(minimum, maximum).toInt();
}
