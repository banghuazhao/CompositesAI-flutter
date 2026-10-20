// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(angles) => "Angles: ${angles}";

  static String m1(unit) => "Too large for ${unit}; check units";

  static String m2(count) => "+${count} more";

  static String m3(count) =>
      "${Intl.plural(count, one: '1 ply', other: '${count} plies')}";

  static String m4(value, unit) => "Total thickness: ${value} ${unit}";

  static String m5(modulus, stress, length, loads) =>
      "Moduli ${modulus} · stress ${stress} · length ${length} · loads ${loads}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Angle_of_Rotation": MessageLookupByLibrary.simpleMessage(
      "Angle of Rotation",
    ),
    "Anisotropic_material": MessageLookupByLibrary.simpleMessage(
      "Anisotropic material",
    ),
    "Area": MessageLookupByLibrary.simpleMessage("Area"),
    "Buckling_Load": MessageLookupByLibrary.simpleMessage("Buckling Load"),
    "Buckling_load_of_column": MessageLookupByLibrary.simpleMessage(
      "Buckling load of column",
    ),
    "Calculate": MessageLookupByLibrary.simpleMessage("Calculate"),
    "Calculator_calculation_failed": MessageLookupByLibrary.simpleMessage(
      "Could not calculate these results. Check the material constants, loads and thickness.",
    ),
    "Calculator_clear_layup": MessageLookupByLibrary.simpleMessage(
      "Clear layup sequence",
    ),
    "Calculator_copy_failed": MessageLookupByLibrary.simpleMessage(
      "Could not copy these results. Please try again.",
    ),
    "Calculator_copy_results": MessageLookupByLibrary.simpleMessage(
      "Copy results",
    ),
    "Calculator_expanded_angles": m0,
    "Calculator_export_failed": MessageLookupByLibrary.simpleMessage(
      "Could not export these results.",
    ),
    "Calculator_export_results": MessageLookupByLibrary.simpleMessage(
      "Export results",
    ),
    "Calculator_finite_thickness": MessageLookupByLibrary.simpleMessage(
      "Enter a finite number",
    ),
    "Calculator_modulus_too_large": m1,
    "Calculator_more_plies": m2,
    "Calculator_ply_count": m3,
    "Calculator_poisson_range": MessageLookupByLibrary.simpleMessage(
      "Must be between -1 and 0.5",
    ),
    "Calculator_positive_number": MessageLookupByLibrary.simpleMessage(
      "Must be greater than zero",
    ),
    "Calculator_positive_thickness": MessageLookupByLibrary.simpleMessage(
      "Thickness must be greater than zero",
    ),
    "Calculator_results_copied": MessageLookupByLibrary.simpleMessage(
      "Results copied to clipboard",
    ),
    "Calculator_share_csv": MessageLookupByLibrary.simpleMessage(
      "Share as CSV",
    ),
    "Calculator_share_pdf": MessageLookupByLibrary.simpleMessage(
      "Share as PDF",
    ),
    "Calculator_si_name": MessageLookupByLibrary.simpleMessage("SI"),
    "Calculator_thickness": MessageLookupByLibrary.simpleMessage("Thickness"),
    "Calculator_too_many_layers": MessageLookupByLibrary.simpleMessage(
      "Too many layers",
    ),
    "Calculator_total_thickness": m4,
    "Calculator_unit_details": m5,
    "Calculator_units": MessageLookupByLibrary.simpleMessage(
      "Calculator units",
    ),
    "Calculator_units_explanation": MessageLookupByLibrary.simpleMessage(
      "Inputs, results and exports use these units. Values you have already typed are not converted.",
    ),
    "Calculator_us_name": MessageLookupByLibrary.simpleMessage("US customary"),
    "Calculator_volume_range": MessageLookupByLibrary.simpleMessage(
      "Must be between 0 and 1",
    ),
    "Calculator_wrong_layup": MessageLookupByLibrary.simpleMessage(
      "Wrong layup sequence",
    ),
    "Compliance_Matrix_S": MessageLookupByLibrary.simpleMessage(
      "Compliance Matrix S",
    ),
    "Composite_Material": MessageLookupByLibrary.simpleMessage(
      "Composite Material",
    ),
    "Constitutive_relation_of_linear_elastic_material":
        MessageLookupByLibrary.simpleMessage(
          "Constitutive relation of linear elastic material",
        ),
    "CountdownDays": MessageLookupByLibrary.simpleMessage("Countdown Days"),
    "Deflection": MessageLookupByLibrary.simpleMessage("Deflection"),
    "Deflections_and_slopes_of_cantilever_beams":
        MessageLookupByLibrary.simpleMessage(
          "Deflections and slopes of cantilever beams",
        ),
    "Deflections_and_slopes_of_simple_beams":
        MessageLookupByLibrary.simpleMessage(
          "Deflections and slopes of simple beams",
        ),
    "Description": MessageLookupByLibrary.simpleMessage("Description"),
    "Displacement": MessageLookupByLibrary.simpleMessage("Displacement"),
    "Engineering_Constants": MessageLookupByLibrary.simpleMessage(
      "Engineering Constants",
    ),
    "Favorites": MessageLookupByLibrary.simpleMessage("Favorites"),
    "Feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
    "FinanceGo": MessageLookupByLibrary.simpleMessage("Finance Go"),
    "Flexure_formula_of_beam": MessageLookupByLibrary.simpleMessage(
      "Flexure formula of beam",
    ),
    "Force": MessageLookupByLibrary.simpleMessage("Force"),
    "Force_displacement_relation_of_bar": MessageLookupByLibrary.simpleMessage(
      "Force-displacement relation of bar",
    ),
    "General_stress_calculation": MessageLookupByLibrary.simpleMessage(
      "General stress calculation",
    ),
    "Inputs": MessageLookupByLibrary.simpleMessage("Inputs"),
    "Isotropic_material": MessageLookupByLibrary.simpleMessage(
      "Isotropic material",
    ),
    "Lamina_Constants": MessageLookupByLibrary.simpleMessage(
      "Lamina Constants",
    ),
    "Lamina_engineering_constants": MessageLookupByLibrary.simpleMessage(
      "Lamina Engineering Constants",
    ),
    "Lamina_stressstrain": MessageLookupByLibrary.simpleMessage(
      "Lamina Stress/Strain",
    ),
    "Laminar_stressstrain": MessageLookupByLibrary.simpleMessage(
      "Laminar Stress/Strain",
    ),
    "Laminate_3D_properties": MessageLookupByLibrary.simpleMessage(
      "Laminate 3D Properties",
    ),
    "Laminate_plate_properties": MessageLookupByLibrary.simpleMessage(
      "Laminate Plate Properties",
    ),
    "Layer_Thickness": MessageLookupByLibrary.simpleMessage("Layer Thickness"),
    "Layup_Angle": MessageLookupByLibrary.simpleMessage("Layup Angle"),
    "Layup_Sequence": MessageLookupByLibrary.simpleMessage("Layup Sequence"),
    "ME_Toolkit": MessageLookupByLibrary.simpleMessage("ME Toolkit"),
    "Mechanics_of_Material": MessageLookupByLibrary.simpleMessage(
      "Mechanics of Material",
    ),
    "Moments_of_Inertia": MessageLookupByLibrary.simpleMessage(
      "Moments of Inertia",
    ),
    "Moments_of_inertia_of_plane_areas": MessageLookupByLibrary.simpleMessage(
      "Moments of inertia of plane areas",
    ),
    "MoneyTracker": MessageLookupByLibrary.simpleMessage("Money Tracker"),
    "Monoclinic_material": MessageLookupByLibrary.simpleMessage(
      "Monoclinic material",
    ),
    "More": MessageLookupByLibrary.simpleMessage("More"),
    "MoreApps": MessageLookupByLibrary.simpleMessage("More Apps"),
    "MyFavourite": MessageLookupByLibrary.simpleMessage("My Favourite"),
    "NASALover": MessageLookupByLibrary.simpleMessage("NASA Lover"),
    "Not_a_number": MessageLookupByLibrary.simpleMessage("Not a number"),
    "NovelsHub": MessageLookupByLibrary.simpleMessage("Novels Hub"),
    "Orthotropic_material": MessageLookupByLibrary.simpleMessage(
      "Orthotropic material",
    ),
    "Plane_Stresses": MessageLookupByLibrary.simpleMessage("Plane Stresses"),
    "Plane_stresses_transformation": MessageLookupByLibrary.simpleMessage(
      "Plane stresses transformation",
    ),
    "Principal_stresses_and_plane": MessageLookupByLibrary.simpleMessage(
      "Principal stresses and plane",
    ),
    "RatethisApp": MessageLookupByLibrary.simpleMessage("Rate this App"),
    "Result": MessageLookupByLibrary.simpleMessage("Result"),
    "Result_Precision": MessageLookupByLibrary.simpleMessage(
      "Result Precision",
    ),
    "Result_Strain": MessageLookupByLibrary.simpleMessage("Result Strain"),
    "Result_Stress": MessageLookupByLibrary.simpleMessage("Result Stress"),
    "Results": MessageLookupByLibrary.simpleMessage("Results"),
    "Settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "SharethisApp": MessageLookupByLibrary.simpleMessage("Share this App"),
    "Slope": MessageLookupByLibrary.simpleMessage("Slope"),
    "Stiffness_Matrix_C": MessageLookupByLibrary.simpleMessage(
      "Stiffness Matrix C",
    ),
    "Stiffness_Matrix_Q": MessageLookupByLibrary.simpleMessage(
      "Stiffness Matrix Q",
    ),
    "Strain": MessageLookupByLibrary.simpleMessage("Strain"),
    "Stress": MessageLookupByLibrary.simpleMessage("Stress"),
    "Stresses_in_a_thin_walled_cylindrical_pressure_vessel":
        MessageLookupByLibrary.simpleMessage(
          "Stresses in a thin-walled cylindrical pressure vessel",
        ),
    "Stresses_in_the_wall_of_a_spherical_shell":
        MessageLookupByLibrary.simpleMessage(
          "Stresses in the wall of a spherical shell",
        ),
    "Stressstrain_of_linear_elastic_material":
        MessageLookupByLibrary.simpleMessage(
          "Stress/strain of linear elastic material",
        ),
    "The_Maximum_Shear_Stress": MessageLookupByLibrary.simpleMessage(
      "The Maximum Shear Stress",
    ),
    "Theory_of_Elasticity": MessageLookupByLibrary.simpleMessage(
      "Theory of Elasticity",
    ),
    "Torsion_formula_of_bar": MessageLookupByLibrary.simpleMessage(
      "Torsion formula of bar",
    ),
    "Transversely_isotropic_material": MessageLookupByLibrary.simpleMessage(
      "Transversely isotropic material",
    ),
    "UDFRC_Properties": MessageLookupByLibrary.simpleMessage(
      "UDFRC Properties",
    ),
  };
}
