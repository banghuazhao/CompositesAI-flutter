import 'package:flutter/widgets.dart';
import 'package:swiftcomp/generated/l10n.dart';

/// Translates the existing calculator validation messages at the UI boundary.
/// Unknown messages pass through so new validation rules remain visible.
String? localizeCalculatorValidation(BuildContext context, String? message) {
  if (message == null) return null;
  final strings = S.maybeOf(context);
  switch (message) {
    case 'Not a number':
      return strings?.Not_a_number ?? 'Not a number';
    case 'Enter a finite number':
      return strings?.Calculator_finite_thickness ?? 'Enter a finite number';
    case 'Not > 0':
      return strings?.Calculator_positive_number ?? 'Must be greater than zero';
    case 'Not in (-1.0, 0.5)':
      return strings?.Calculator_poisson_range ?? 'Must be between -1 and 0.5';
    case 'Not in [0.0, 1.0]':
      return strings?.Calculator_volume_range ?? 'Must be between 0 and 1';
  }

  const modulusPrefix = 'Too large for ';
  const modulusSuffix = '; check units';
  if (message.startsWith(modulusPrefix) && message.endsWith(modulusSuffix)) {
    final unit = message.substring(
        modulusPrefix.length, message.length - modulusSuffix.length);
    return strings?.Calculator_modulus_too_large(unit) ?? message;
  }
  return message;
}
