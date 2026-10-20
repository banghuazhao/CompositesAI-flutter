// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `More`
  String get More {
    return Intl.message('More', name: 'More', desc: '', args: []);
  }

  /// `My Favourite`
  String get MyFavourite {
    return Intl.message(
      'My Favourite',
      name: 'MyFavourite',
      desc: '',
      args: [],
    );
  }

  /// `Feedback`
  String get Feedback {
    return Intl.message('Feedback', name: 'Feedback', desc: '', args: []);
  }

  /// `Rate this App`
  String get RatethisApp {
    return Intl.message(
      'Rate this App',
      name: 'RatethisApp',
      desc: '',
      args: [],
    );
  }

  /// `Share this App`
  String get SharethisApp {
    return Intl.message(
      'Share this App',
      name: 'SharethisApp',
      desc: '',
      args: [],
    );
  }

  /// `More Apps`
  String get MoreApps {
    return Intl.message('More Apps', name: 'MoreApps', desc: '', args: []);
  }

  /// `Countdown Days`
  String get CountdownDays {
    return Intl.message(
      'Countdown Days',
      name: 'CountdownDays',
      desc: '',
      args: [],
    );
  }

  /// `Money Tracker`
  String get MoneyTracker {
    return Intl.message(
      'Money Tracker',
      name: 'MoneyTracker',
      desc: '',
      args: [],
    );
  }

  /// `Novels Hub`
  String get NovelsHub {
    return Intl.message('Novels Hub', name: 'NovelsHub', desc: '', args: []);
  }

  /// `Finance Go`
  String get FinanceGo {
    return Intl.message('Finance Go', name: 'FinanceGo', desc: '', args: []);
  }

  /// `NASA Lover`
  String get NASALover {
    return Intl.message('NASA Lover', name: 'NASALover', desc: '', args: []);
  }

  /// `Settings`
  String get Settings {
    return Intl.message('Settings', name: 'Settings', desc: '', args: []);
  }

  /// `Result`
  String get Result {
    return Intl.message('Result', name: 'Result', desc: '', args: []);
  }

  /// `Results`
  String get Results {
    return Intl.message('Results', name: 'Results', desc: '', args: []);
  }

  /// `Result Precision`
  String get Result_Precision {
    return Intl.message(
      'Result Precision',
      name: 'Result_Precision',
      desc: '',
      args: [],
    );
  }

  /// `Result Stress`
  String get Result_Stress {
    return Intl.message(
      'Result Stress',
      name: 'Result_Stress',
      desc: '',
      args: [],
    );
  }

  /// `Result Strain`
  String get Result_Strain {
    return Intl.message(
      'Result Strain',
      name: 'Result_Strain',
      desc: '',
      args: [],
    );
  }

  /// `Calculate`
  String get Calculate {
    return Intl.message('Calculate', name: 'Calculate', desc: '', args: []);
  }

  /// `Stress`
  String get Stress {
    return Intl.message('Stress', name: 'Stress', desc: '', args: []);
  }

  /// `Strain`
  String get Strain {
    return Intl.message('Strain', name: 'Strain', desc: '', args: []);
  }

  /// `Buckling Load`
  String get Buckling_Load {
    return Intl.message(
      'Buckling Load',
      name: 'Buckling_Load',
      desc: '',
      args: [],
    );
  }

  /// `Deflection`
  String get Deflection {
    return Intl.message('Deflection', name: 'Deflection', desc: '', args: []);
  }

  /// `The Maximum Shear Stress`
  String get The_Maximum_Shear_Stress {
    return Intl.message(
      'The Maximum Shear Stress',
      name: 'The_Maximum_Shear_Stress',
      desc: '',
      args: [],
    );
  }

  /// `Displacement`
  String get Displacement {
    return Intl.message(
      'Displacement',
      name: 'Displacement',
      desc: '',
      args: [],
    );
  }

  /// `Moments of Inertia`
  String get Moments_of_Inertia {
    return Intl.message(
      'Moments of Inertia',
      name: 'Moments_of_Inertia',
      desc: '',
      args: [],
    );
  }

  /// `Stiffness Matrix C`
  String get Stiffness_Matrix_C {
    return Intl.message(
      'Stiffness Matrix C',
      name: 'Stiffness_Matrix_C',
      desc: '',
      args: [],
    );
  }

  /// `Stiffness Matrix Q`
  String get Stiffness_Matrix_Q {
    return Intl.message(
      'Stiffness Matrix Q',
      name: 'Stiffness_Matrix_Q',
      desc: '',
      args: [],
    );
  }

  /// `Compliance Matrix S`
  String get Compliance_Matrix_S {
    return Intl.message(
      'Compliance Matrix S',
      name: 'Compliance_Matrix_S',
      desc: '',
      args: [],
    );
  }

  /// `Area`
  String get Area {
    return Intl.message('Area', name: 'Area', desc: '', args: []);
  }

  /// `Inputs`
  String get Inputs {
    return Intl.message('Inputs', name: 'Inputs', desc: '', args: []);
  }

  /// `Engineering Constants`
  String get Engineering_Constants {
    return Intl.message(
      'Engineering Constants',
      name: 'Engineering_Constants',
      desc: '',
      args: [],
    );
  }

  /// `General stress calculation`
  String get General_stress_calculation {
    return Intl.message(
      'General stress calculation',
      name: 'General_stress_calculation',
      desc: '',
      args: [],
    );
  }

  /// `Force-displacement relation of bar`
  String get Force_displacement_relation_of_bar {
    return Intl.message(
      'Force-displacement relation of bar',
      name: 'Force_displacement_relation_of_bar',
      desc: '',
      args: [],
    );
  }

  /// `Moments of inertia of plane areas`
  String get Moments_of_inertia_of_plane_areas {
    return Intl.message(
      'Moments of inertia of plane areas',
      name: 'Moments_of_inertia_of_plane_areas',
      desc: '',
      args: [],
    );
  }

  /// `Torsion formula of bar`
  String get Torsion_formula_of_bar {
    return Intl.message(
      'Torsion formula of bar',
      name: 'Torsion_formula_of_bar',
      desc: '',
      args: [],
    );
  }

  /// `Flexure formula of beam`
  String get Flexure_formula_of_beam {
    return Intl.message(
      'Flexure formula of beam',
      name: 'Flexure_formula_of_beam',
      desc: '',
      args: [],
    );
  }

  /// `Deflections and slopes of cantilever beams`
  String get Deflections_and_slopes_of_cantilever_beams {
    return Intl.message(
      'Deflections and slopes of cantilever beams',
      name: 'Deflections_and_slopes_of_cantilever_beams',
      desc: '',
      args: [],
    );
  }

  /// `Deflections and slopes of simple beams`
  String get Deflections_and_slopes_of_simple_beams {
    return Intl.message(
      'Deflections and slopes of simple beams',
      name: 'Deflections_and_slopes_of_simple_beams',
      desc: '',
      args: [],
    );
  }

  /// `Plane stresses transformation`
  String get Plane_stresses_transformation {
    return Intl.message(
      'Plane stresses transformation',
      name: 'Plane_stresses_transformation',
      desc: '',
      args: [],
    );
  }

  /// `Principal stresses and plane`
  String get Principal_stresses_and_plane {
    return Intl.message(
      'Principal stresses and plane',
      name: 'Principal_stresses_and_plane',
      desc: '',
      args: [],
    );
  }

  /// `Stresses in the wall of a spherical shell`
  String get Stresses_in_the_wall_of_a_spherical_shell {
    return Intl.message(
      'Stresses in the wall of a spherical shell',
      name: 'Stresses_in_the_wall_of_a_spherical_shell',
      desc: '',
      args: [],
    );
  }

  /// `Stresses in a thin-walled cylindrical pressure vessel`
  String get Stresses_in_a_thin_walled_cylindrical_pressure_vessel {
    return Intl.message(
      'Stresses in a thin-walled cylindrical pressure vessel',
      name: 'Stresses_in_a_thin_walled_cylindrical_pressure_vessel',
      desc: '',
      args: [],
    );
  }

  /// `Buckling load of column`
  String get Buckling_load_of_column {
    return Intl.message(
      'Buckling load of column',
      name: 'Buckling_load_of_column',
      desc: '',
      args: [],
    );
  }

  /// `Constitutive relation of linear elastic material`
  String get Constitutive_relation_of_linear_elastic_material {
    return Intl.message(
      'Constitutive relation of linear elastic material',
      name: 'Constitutive_relation_of_linear_elastic_material',
      desc: '',
      args: [],
    );
  }

  /// `Stress/strain of linear elastic material`
  String get Stressstrain_of_linear_elastic_material {
    return Intl.message(
      'Stress/strain of linear elastic material',
      name: 'Stressstrain_of_linear_elastic_material',
      desc: '',
      args: [],
    );
  }

  /// `Lamina Stress/Strain`
  String get Lamina_stressstrain {
    return Intl.message(
      'Lamina Stress/Strain',
      name: 'Lamina_stressstrain',
      desc: '',
      args: [],
    );
  }

  /// `Lamina Engineering Constants`
  String get Lamina_engineering_constants {
    return Intl.message(
      'Lamina Engineering Constants',
      name: 'Lamina_engineering_constants',
      desc: '',
      args: [],
    );
  }

  /// `Laminar Stress/Strain`
  String get Laminar_stressstrain {
    return Intl.message(
      'Laminar Stress/Strain',
      name: 'Laminar_stressstrain',
      desc: '',
      args: [],
    );
  }

  /// `Laminate Plate Properties`
  String get Laminate_plate_properties {
    return Intl.message(
      'Laminate Plate Properties',
      name: 'Laminate_plate_properties',
      desc: '',
      args: [],
    );
  }

  /// `Laminate 3D Properties`
  String get Laminate_3D_properties {
    return Intl.message(
      'Laminate 3D Properties',
      name: 'Laminate_3D_properties',
      desc: '',
      args: [],
    );
  }

  /// `UDFRC Properties`
  String get UDFRC_Properties {
    return Intl.message(
      'UDFRC Properties',
      name: 'UDFRC_Properties',
      desc: '',
      args: [],
    );
  }

  /// `Mechanics of Material`
  String get Mechanics_of_Material {
    return Intl.message(
      'Mechanics of Material',
      name: 'Mechanics_of_Material',
      desc: '',
      args: [],
    );
  }

  /// `Theory of Elasticity`
  String get Theory_of_Elasticity {
    return Intl.message(
      'Theory of Elasticity',
      name: 'Theory_of_Elasticity',
      desc: '',
      args: [],
    );
  }

  /// `Composite Material`
  String get Composite_Material {
    return Intl.message(
      'Composite Material',
      name: 'Composite_Material',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get Description {
    return Intl.message('Description', name: 'Description', desc: '', args: []);
  }

  /// `Force`
  String get Force {
    return Intl.message('Force', name: 'Force', desc: '', args: []);
  }

  /// `Angle of Rotation`
  String get Angle_of_Rotation {
    return Intl.message(
      'Angle of Rotation',
      name: 'Angle_of_Rotation',
      desc: '',
      args: [],
    );
  }

  /// `Plane Stresses`
  String get Plane_Stresses {
    return Intl.message(
      'Plane Stresses',
      name: 'Plane_Stresses',
      desc: '',
      args: [],
    );
  }

  /// `Lamina Constants`
  String get Lamina_Constants {
    return Intl.message(
      'Lamina Constants',
      name: 'Lamina_Constants',
      desc: '',
      args: [],
    );
  }

  /// `Layup Sequence`
  String get Layup_Sequence {
    return Intl.message(
      'Layup Sequence',
      name: 'Layup_Sequence',
      desc: '',
      args: [],
    );
  }

  /// `Layer Thickness`
  String get Layer_Thickness {
    return Intl.message(
      'Layer Thickness',
      name: 'Layer_Thickness',
      desc: '',
      args: [],
    );
  }

  /// `ME Toolkit`
  String get ME_Toolkit {
    return Intl.message('ME Toolkit', name: 'ME_Toolkit', desc: '', args: []);
  }

  /// `Favorites`
  String get Favorites {
    return Intl.message('Favorites', name: 'Favorites', desc: '', args: []);
  }

  /// `Slope`
  String get Slope {
    return Intl.message('Slope', name: 'Slope', desc: '', args: []);
  }

  /// `Not a number`
  String get Not_a_number {
    return Intl.message(
      'Not a number',
      name: 'Not_a_number',
      desc: '',
      args: [],
    );
  }

  /// `Layup Angle`
  String get Layup_Angle {
    return Intl.message('Layup Angle', name: 'Layup_Angle', desc: '', args: []);
  }

  /// `Isotropic material`
  String get Isotropic_material {
    return Intl.message(
      'Isotropic material',
      name: 'Isotropic_material',
      desc: '',
      args: [],
    );
  }

  /// `Transversely isotropic material`
  String get Transversely_isotropic_material {
    return Intl.message(
      'Transversely isotropic material',
      name: 'Transversely_isotropic_material',
      desc: '',
      args: [],
    );
  }

  /// `Orthotropic material`
  String get Orthotropic_material {
    return Intl.message(
      'Orthotropic material',
      name: 'Orthotropic_material',
      desc: '',
      args: [],
    );
  }

  /// `Monoclinic material`
  String get Monoclinic_material {
    return Intl.message(
      'Monoclinic material',
      name: 'Monoclinic_material',
      desc: '',
      args: [],
    );
  }

  /// `Anisotropic material`
  String get Anisotropic_material {
    return Intl.message(
      'Anisotropic material',
      name: 'Anisotropic_material',
      desc: '',
      args: [],
    );
  }

  /// `Thickness`
  String get Calculator_thickness {
    return Intl.message(
      'Thickness',
      name: 'Calculator_thickness',
      desc: '',
      args: [],
    );
  }

  /// `Enter a finite number`
  String get Calculator_finite_thickness {
    return Intl.message(
      'Enter a finite number',
      name: 'Calculator_finite_thickness',
      desc: '',
      args: [],
    );
  }

  /// `Thickness must be greater than zero`
  String get Calculator_positive_thickness {
    return Intl.message(
      'Thickness must be greater than zero',
      name: 'Calculator_positive_thickness',
      desc: '',
      args: [],
    );
  }

  /// `Export results`
  String get Calculator_export_results {
    return Intl.message(
      'Export results',
      name: 'Calculator_export_results',
      desc: '',
      args: [],
    );
  }

  /// `Copy results`
  String get Calculator_copy_results {
    return Intl.message(
      'Copy results',
      name: 'Calculator_copy_results',
      desc: '',
      args: [],
    );
  }

  /// `Share as CSV`
  String get Calculator_share_csv {
    return Intl.message(
      'Share as CSV',
      name: 'Calculator_share_csv',
      desc: '',
      args: [],
    );
  }

  /// `Share as PDF`
  String get Calculator_share_pdf {
    return Intl.message(
      'Share as PDF',
      name: 'Calculator_share_pdf',
      desc: '',
      args: [],
    );
  }

  /// `Results copied to clipboard`
  String get Calculator_results_copied {
    return Intl.message(
      'Results copied to clipboard',
      name: 'Calculator_results_copied',
      desc: '',
      args: [],
    );
  }

  /// `Could not copy these results. Please try again.`
  String get Calculator_copy_failed {
    return Intl.message(
      'Could not copy these results. Please try again.',
      name: 'Calculator_copy_failed',
      desc: '',
      args: [],
    );
  }

  /// `Could not export these results.`
  String get Calculator_export_failed {
    return Intl.message(
      'Could not export these results.',
      name: 'Calculator_export_failed',
      desc: '',
      args: [],
    );
  }

  /// `Calculator units`
  String get Calculator_units {
    return Intl.message(
      'Calculator units',
      name: 'Calculator_units',
      desc: '',
      args: [],
    );
  }

  /// `Inputs, results and exports use these units. Values you have already typed are not converted.`
  String get Calculator_units_explanation {
    return Intl.message(
      'Inputs, results and exports use these units. Values you have already typed are not converted.',
      name: 'Calculator_units_explanation',
      desc: '',
      args: [],
    );
  }

  /// `SI`
  String get Calculator_si_name {
    return Intl.message('SI', name: 'Calculator_si_name', desc: '', args: []);
  }

  /// `US customary`
  String get Calculator_us_name {
    return Intl.message(
      'US customary',
      name: 'Calculator_us_name',
      desc: '',
      args: [],
    );
  }

  /// `Moduli {modulus} · stress {stress} · length {length} · loads {loads}`
  String Calculator_unit_details(
    Object modulus,
    Object stress,
    Object length,
    Object loads,
  ) {
    return Intl.message(
      'Moduli $modulus · stress $stress · length $length · loads $loads',
      name: 'Calculator_unit_details',
      desc: '',
      args: [modulus, stress, length, loads],
    );
  }

  /// `Must be greater than zero`
  String get Calculator_positive_number {
    return Intl.message(
      'Must be greater than zero',
      name: 'Calculator_positive_number',
      desc: '',
      args: [],
    );
  }

  /// `Must be between -1 and 0.5`
  String get Calculator_poisson_range {
    return Intl.message(
      'Must be between -1 and 0.5',
      name: 'Calculator_poisson_range',
      desc: '',
      args: [],
    );
  }

  /// `Must be between 0 and 1`
  String get Calculator_volume_range {
    return Intl.message(
      'Must be between 0 and 1',
      name: 'Calculator_volume_range',
      desc: '',
      args: [],
    );
  }

  /// `Too large for {unit}; check units`
  String Calculator_modulus_too_large(Object unit) {
    return Intl.message(
      'Too large for $unit; check units',
      name: 'Calculator_modulus_too_large',
      desc: '',
      args: [unit],
    );
  }

  /// `Wrong layup sequence`
  String get Calculator_wrong_layup {
    return Intl.message(
      'Wrong layup sequence',
      name: 'Calculator_wrong_layup',
      desc: '',
      args: [],
    );
  }

  /// `Too many layers`
  String get Calculator_too_many_layers {
    return Intl.message(
      'Too many layers',
      name: 'Calculator_too_many_layers',
      desc: '',
      args: [],
    );
  }

  /// `Clear layup sequence`
  String get Calculator_clear_layup {
    return Intl.message(
      'Clear layup sequence',
      name: 'Calculator_clear_layup',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{1 ply} other{{count} plies}}`
  String Calculator_ply_count(int count) {
    return Intl.plural(
      count,
      one: '1 ply',
      other: '$count plies',
      name: 'Calculator_ply_count',
      desc: '',
      args: [count],
    );
  }

  /// `Total thickness: {value} {unit}`
  String Calculator_total_thickness(Object value, Object unit) {
    return Intl.message(
      'Total thickness: $value $unit',
      name: 'Calculator_total_thickness',
      desc: '',
      args: [value, unit],
    );
  }

  /// `Angles: {angles}`
  String Calculator_expanded_angles(Object angles) {
    return Intl.message(
      'Angles: $angles',
      name: 'Calculator_expanded_angles',
      desc: '',
      args: [angles],
    );
  }

  /// `+{count} more`
  String Calculator_more_plies(int count) {
    return Intl.message(
      '+$count more',
      name: 'Calculator_more_plies',
      desc: '',
      args: [count],
    );
  }

  /// `Could not calculate these results. Check the material constants, loads and thickness.`
  String get Calculator_calculation_failed {
    return Intl.message(
      'Could not calculate these results. Check the material constants, loads and thickness.',
      name: 'Calculator_calculation_failed',
      desc: '',
      args: [],
    );
  }

  /// `Tap a point or hover to inspect ply values`
  String get Calculator_chart_inspection_hint {
    return Intl.message(
      'Tap a point or hover to inspect ply values',
      name: 'Calculator_chart_inspection_hint',
      desc: '',
      args: [],
    );
  }

  /// `Depth: {value} {unit}`
  String Calculator_chart_depth(Object value, Object unit) {
    return Intl.message(
      'Depth: $value $unit',
      name: 'Calculator_chart_depth',
      desc: '',
      args: [value, unit],
    );
  }

  /// `Ply {ply} · {surface}`
  String Calculator_chart_ply_surface(Object ply, Object surface) {
    return Intl.message(
      'Ply $ply · $surface',
      name: 'Calculator_chart_ply_surface',
      desc: '',
      args: [ply, surface],
    );
  }

  /// `Bottom`
  String get Calculator_surface_bottom {
    return Intl.message(
      'Bottom',
      name: 'Calculator_surface_bottom',
      desc: '',
      args: [],
    );
  }

  /// `Top`
  String get Calculator_surface_top {
    return Intl.message(
      'Top',
      name: 'Calculator_surface_top',
      desc: '',
      args: [],
    );
  }

  /// `Replace saved material?`
  String get Calculator_replace_material_title {
    return Intl.message(
      'Replace saved material?',
      name: 'Calculator_replace_material_title',
      desc: '',
      args: [],
    );
  }

  /// `A saved material named "{name}" already exists. Replace its saved values or choose another name.`
  String Calculator_replace_material_message(Object name) {
    return Intl.message(
      'A saved material named "$name" already exists. Replace its saved values or choose another name.',
      name: 'Calculator_replace_material_message',
      desc: '',
      args: [name],
    );
  }

  /// `Replace`
  String get Calculator_replace_material {
    return Intl.message(
      'Replace',
      name: 'Calculator_replace_material',
      desc: '',
      args: [],
    );
  }

  /// `Choose another name`
  String get Calculator_choose_another_name {
    return Intl.message(
      'Choose another name',
      name: 'Calculator_choose_another_name',
      desc: '',
      args: [],
    );
  }

  /// `Could not delete this material. Please try again.`
  String get Calculator_material_delete_failed {
    return Intl.message(
      'Could not delete this material. Please try again.',
      name: 'Calculator_material_delete_failed',
      desc: '',
      args: [],
    );
  }

  /// `Material details`
  String get Calculator_material_details {
    return Intl.message(
      'Material details',
      name: 'Calculator_material_details',
      desc: '',
      args: [],
    );
  }

  /// `Material type`
  String get Calculator_material_type {
    return Intl.message(
      'Material type',
      name: 'Calculator_material_type',
      desc: '',
      args: [],
    );
  }

  /// `Unidirectional lamina`
  String get Calculator_material_kind_lamina {
    return Intl.message(
      'Unidirectional lamina',
      name: 'Calculator_material_kind_lamina',
      desc: '',
      args: [],
    );
  }

  /// `Fiber`
  String get Calculator_material_kind_fiber {
    return Intl.message(
      'Fiber',
      name: 'Calculator_material_kind_fiber',
      desc: '',
      args: [],
    );
  }

  /// `Matrix`
  String get Calculator_material_kind_matrix {
    return Intl.message(
      'Matrix',
      name: 'Calculator_material_kind_matrix',
      desc: '',
      args: [],
    );
  }

  /// `Source`
  String get Calculator_material_source {
    return Intl.message(
      'Source',
      name: 'Calculator_material_source',
      desc: '',
      args: [],
    );
  }

  /// `Elastic properties`
  String get Calculator_material_elastic_properties {
    return Intl.message(
      'Elastic properties',
      name: 'Calculator_material_elastic_properties',
      desc: '',
      args: [],
    );
  }

  /// `Thermal expansion`
  String get Calculator_material_thermal_properties {
    return Intl.message(
      'Thermal expansion',
      name: 'Calculator_material_thermal_properties',
      desc: '',
      args: [],
    );
  }

  /// `Strengths`
  String get Calculator_material_strengths {
    return Intl.message(
      'Strengths',
      name: 'Calculator_material_strengths',
      desc: '',
      args: [],
    );
  }

  /// `Not provided`
  String get Calculator_material_not_provided {
    return Intl.message(
      'Not provided',
      name: 'Calculator_material_not_provided',
      desc: '',
      args: [],
    );
  }

  /// `Missing elastic values keep the current inputs. Missing thermal or strength groups also keep the current inputs.`
  String get Calculator_material_missing_note {
    return Intl.message(
      'Missing elastic values keep the current inputs. Missing thermal or strength groups also keep the current inputs.',
      name: 'Calculator_material_missing_note',
      desc: '',
      args: [],
    );
  }

  /// `Strengths are applied together only when all five values are provided.`
  String get Calculator_material_strengths_note {
    return Intl.message(
      'Strengths are applied together only when all five values are provided.',
      name: 'Calculator_material_strengths_note',
      desc: '',
      args: [],
    );
  }

  /// `Thermal values need α11 (α for isotropic materials). For laminae and fibers, missing α22 uses α11 and shear CTE is set to zero.`
  String get Calculator_material_thermal_note {
    return Intl.message(
      'Thermal values need α11 (α for isotropic materials). For laminae and fibers, missing α22 uses α11 and shear CTE is set to zero.',
      name: 'Calculator_material_thermal_note',
      desc: '',
      args: [],
    );
  }

  /// `Apply material`
  String get Calculator_apply_material {
    return Intl.message(
      'Apply material',
      name: 'Calculator_apply_material',
      desc: '',
      args: [],
    );
  }

  /// `Export my materials (JSON)`
  String get Calculator_export_materials {
    return Intl.message(
      'Export my materials (JSON)',
      name: 'Calculator_export_materials',
      desc: '',
      args: [],
    );
  }

  /// `Exports all saved materials in SI units, including materials outside the current search.`
  String get Calculator_export_materials_help {
    return Intl.message(
      'Exports all saved materials in SI units, including materials outside the current search.',
      name: 'Calculator_export_materials_help',
      desc: '',
      args: [],
    );
  }

  /// `Could not export saved materials. Please try again.`
  String get Calculator_material_export_failed {
    return Intl.message(
      'Could not export saved materials. Please try again.',
      name: 'Calculator_material_export_failed',
      desc: '',
      args: [],
    );
  }

  /// `Save a custom material to enable JSON export.`
  String get Calculator_material_export_empty {
    return Intl.message(
      'Save a custom material to enable JSON export.',
      name: 'Calculator_material_export_empty',
      desc: '',
      args: [],
    );
  }

  /// `Criterion`
  String get Calculator_failure_criterion {
    return Intl.message(
      'Criterion',
      name: 'Calculator_failure_criterion',
      desc: '',
      args: [],
    );
  }

  /// `All criteria`
  String get Calculator_all_failure_criteria {
    return Intl.message(
      'All criteria',
      name: 'Calculator_all_failure_criteria',
      desc: '',
      args: [],
    );
  }

  /// `Failing surfaces only`
  String get Calculator_failed_surfaces_only {
    return Intl.message(
      'Failing surfaces only',
      name: 'Calculator_failed_surfaces_only',
      desc: '',
      args: [],
    );
  }

  /// `No failing surfaces match this criterion.`
  String get Calculator_no_failed_surfaces {
    return Intl.message(
      'No failing surfaces match this criterion.',
      name: 'Calculator_no_failed_surfaces',
      desc: '',
      args: [],
    );
  }

  /// `{shown} of {total} surfaces shown. Exports include all surfaces.`
  String Calculator_failure_filter_summary(Object shown, Object total) {
    return Intl.message(
      '$shown of $total surfaces shown. Exports include all surfaces.',
      name: 'Calculator_failure_filter_summary',
      desc: '',
      args: [shown, total],
    );
  }

  /// `Exports always include every surface and criterion.`
  String get Calculator_failure_exports_all {
    return Intl.message(
      'Exports always include every surface and criterion.',
      name: 'Calculator_failure_exports_all',
      desc: '',
      args: [],
    );
  }

  /// `No failure results are available.`
  String get Calculator_no_failure_results {
    return Intl.message(
      'No failure results are available.',
      name: 'Calculator_no_failure_results',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'HK'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
