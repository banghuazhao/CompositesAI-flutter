import 'package:flutter/material.dart';

enum ExplainType {
  fiber_volumn_fraction,
  layup_sequence,
  material,
}

class Explain {
  static Widget getExplain(ExplainType type, BuildContext context) {
    if (type == ExplainType.fiber_volumn_fraction) {
      return Text("""
The fiber volume fraction is defined as the fiber volume divided by the total volume of the composite:

fiber volume fraction = fiber volume / total volume of the composite

The fiber is the reinforcing phase in a composite. In fiber direction, it is stiff and strong and serves as the main load carrier. The matrix is the supporting phase in a composite, which protects the reinforcing phase and transfers the load to the reinforcing phases.
 """);
    }

    if (type == ExplainType.layup_sequence) {
      return Text("""
The stacking sequence is the layup angles from the bottom surface to the top surface.

The format of stacking sequence is [xx/xx/xx/xx/..]msn
xx: Layup angle
m: Number of repetition before symmetry
s: Symmetry or not
n: Number of repetition after symmetry

• Examples:
Cross-ply laminates: [0/90]
Balanced laminates: [45/-45]
[0/90]2 : [0/90/0/90]
[0/90]s : [0/90/90/0]
[30/-30]2s : [30/-30/30/-30/-30/30/-30/30]
[30/-30]s2 : [30/-30/-30/30/30/-30/-30/30]

The layer thickness is the thickness for each lamina. Note, it doesn't need layer thickness information for solid model.
""");
    }

    if (type == ExplainType.material) {
      return Text("""
• Isotropic Material:
Elastic: E, nu

• Transversely Material:
Elastic: E1, E2, G12, nu12, nu23

• Orthotropic Material:
Elastic: E1, E2, E3, G12, G13, G23, nu12, nu13, nu23

• Anisotropic Material:
Elastic: C11, C12, C13, C14, C15, C16, C22, C23, C24, C25, C26, C33, C34, C35, C36, C44, C45, C46, C55, C56, C66
""");
    }

    return Container();
  }
}
