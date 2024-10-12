import 'package:composite_calculator/models/in-plane-properties.dart';

class LaminatePlatePropertiesOutput {
  List<List<double>> A;
  List<List<double>> B;
  List<List<double>> D;

  InPlaneProperties inPlaneProperties;
  InPlaneProperties flexuralProperties;

  LaminatePlatePropertiesOutput({
    this.A = const [],
    this.B = const [],
    this.D = const [],
    InPlaneProperties? inPlaneProperties,
    InPlaneProperties? flexuralProperties,
  })  : inPlaneProperties = inPlaneProperties ?? InPlaneProperties(),
        flexuralProperties = flexuralProperties ?? InPlaneProperties();

  Map<String, dynamic> toJson() {
    return {
      'A': A,
      'B': B,
      'D': D,
      'in-plane_properties': inPlaneProperties,
      'flexural_properties': flexuralProperties,
    };
  }
}
