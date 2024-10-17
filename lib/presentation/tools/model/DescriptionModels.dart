import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

enum DescriptionType {
  lamina_stress_strain,
  lamina_engineering_constants,
  laminate_stress_strain,
  Laminate_plate_properties,
  laminate_3d_properties,
  UDFRC_rules_of_mixtures,
}

class DescriptionModels {
  static Widget getDescription(DescriptionType type, BuildContext context) {
    if (type == DescriptionType.lamina_stress_strain) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("""
Compute the stress/strain of an orthotropic lamina. The plane stress-strain relations in the material coordinate system can be expressed as:""",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(
            height: 12,
          ),
          Center(
            child: Math.tex(
              r'''\begin{Bmatrix}
  \varepsilon_{11} \\
  \varepsilon_{22} \\
  \gamma_{12}
\end{Bmatrix} = \begin{bmatrix}
  \frac{1}{E_1} & -\frac{\nu_{12}}{E_1} & 0 \\
  -\frac{\nu_{12}}{E_1} & \frac{1}{E_2}  & 0 \\
  0 & 0 & \frac{1}{G_{12}}
\end{bmatrix} \begin{Bmatrix}
  \sigma_{11} \\
  \sigma_{22} \\
  \sigma_{12}
\end{Bmatrix}''',
              mathStyle: MathStyle.script,
              textStyle: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    }

    if (type == DescriptionType.lamina_engineering_constants) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("""
Calculate the engineering constant of an orthotropic lamina for different angles. The plane stress-strain relations in the material coordinate system can be expressed as:""",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(
            height: 12,
          ),
          Center(
            child: Math.tex(
              r'''\begin{Bmatrix}
  \varepsilon_{11} \\
  \varepsilon_{22} \\
  \gamma_{12}
\end{Bmatrix} = \begin{bmatrix}
  \frac{1}{E_1} & -\frac{\nu_{12}}{E_1} & 0 \\
  -\frac{\nu_{12}}{E_1} & \frac{1}{E_2}  & 0 \\
  0 & 0 & \frac{1}{G_{12}}
\end{bmatrix} \begin{Bmatrix}
  \sigma_{11} \\
  \sigma_{22} \\
  \sigma_{12}
\end{Bmatrix}''',
              mathStyle: MathStyle.display,
              textStyle: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      );
    }

    if (type == DescriptionType.laminate_3d_properties) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("""
Calculate 3D properties of a laminate including effective 3D stiffness matrix, compliance matrix, and engineering constants. The 3D constitutive relations can be expressed using the effective 3D stiffness matrix as:""",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(
            height: 12,
          ),
          Center(
            child: Math.tex(
              r'''\begin{Bmatrix}
  \sigma_{11} \\
  \sigma_{22} \\
  \sigma_{33} \\
  \sigma_{23} \\
  \sigma_{13} \\
  \sigma_{12}
\end{Bmatrix} = 
\begin{bmatrix}
  C_{11} & C_{12} & C_{13} & C_{14} & C_{15} & C_{16} \\
  C_{12} & C_{22} & C_{23} & C_{24} & C_{25} & C_{26} \\
  C_{13} & C_{23} & C_{33} & C_{34} & C_{35} & C_{36} \\
  C_{14} & C_{24} & C_{34} & C_{44} & C_{45} & C_{46} \\
  C_{15} & C_{25} & C_{35} & C_{45} & C_{55} & C_{56} \\
  C_{16} & C_{26} & C_{36} & C_{46} & C_{56} & C_{66} 
\end{bmatrix} 
\begin{Bmatrix}
  \varepsilon_{11} \\
  \varepsilon_{22} \\
  \varepsilon_{33} \\
  2\gamma_{23} \\
  2\gamma_{13} \\
  2\gamma_{12}
\end{Bmatrix}''',
              mathStyle: MathStyle.script,
              textStyle: TextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }

    if (type == DescriptionType.Laminate_plate_properties) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("""
Calculate the plate properties of a laminate. The constitutive relations according to the classical lamination theory is:""",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(
            height: 12,
          ),
          Center(
            child: Math.tex(
              r'''\begin{Bmatrix}
  N_{11} \\
  N_{22} \\
  N_{12} \\
  M_{11} \\
  M_{22} \\
  M_{12}
\end{Bmatrix} = 
\begin{bmatrix}
  A_{11} & A_{12} & A_{16} & B_{11} & B_{12} & B_{16} \\
  A_{12} & A_{22} & A_{26} & B_{12} & B_{22} & B_{26} \\
  A_{16} & A_{26} & A_{66} & B_{16} & B_{26} & B_{66} \\
  B_{11} & B_{12} & B_{16} & D_{11} & D_{12} & D_{16} \\
  B_{12} & B_{22} & B_{26} & D_{12} & D_{22} & D_{26} \\
  B_{16} & B_{26} & B_{66} & D_{16} & D_{26} & D_{66} 
\end{bmatrix} 
\begin{Bmatrix}
  \epsilon_{11} \\
  \epsilon_{22} \\
  2\epsilon_{12} \\
  \kappa_{11} \\
  \kappa_{22} \\
  2\kappa_{12}
\end{Bmatrix}''',
              mathStyle: MathStyle.script,
              textStyle: TextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }

    if (type == DescriptionType.laminate_stress_strain) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("""
Calculate the plate strains/curvatures in terms of stress resultants, or vice versa. Compute the laminar stresses and strains. The constitutive relations according to the classical lamination theory is:""",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(
            height: 12,
          ),
          Center(
            child: Math.tex(
              r'''\begin{Bmatrix}
  N_{11} \\
  N_{22} \\
  N_{12} \\
  M_{11} \\
  M_{22} \\
  M_{12}
\end{Bmatrix} = 
\begin{bmatrix}
  A_{11} & A_{12} & A_{16} & B_{11} & B_{12} & B_{16} \\
  A_{12} & A_{22} & A_{26} & B_{12} & B_{22} & B_{26} \\
  A_{16} & A_{26} & A_{66} & B_{16} & B_{26} & B_{66} \\
  B_{11} & B_{12} & B_{16} & D_{11} & D_{12} & D_{16} \\
  B_{12} & B_{22} & B_{26} & D_{12} & D_{22} & D_{26} \\
  B_{16} & B_{26} & B_{66} & D_{16} & D_{26} & D_{66} 
\end{bmatrix} 
\begin{Bmatrix}
  \epsilon_{11} \\
  \epsilon_{22} \\
  2\epsilon_{12} \\
  \kappa_{11} \\
  \kappa_{22} \\
  2\kappa_{12}
\end{Bmatrix}''',
              mathStyle: MathStyle.script,
              textStyle: TextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }

    if (type == DescriptionType.UDFRC_rules_of_mixtures) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("""
Calculate properties (stiffness matrix, compliance matrix, and engineering constants) of unidirectional fiber reinforced composites (UDFRCs) using three rules of mixture:
1. Voigt rules of mixtures: strains are assumed to uniform.
2. Reuss rules of mixtures: stresses are assumed to be uniform.
3. Hybrid rules of mixtures: the axial strain is assumed to be uniform, and the stress components in other directions are assumed to be uniform.
""", style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }

    return Container();
  }
}
