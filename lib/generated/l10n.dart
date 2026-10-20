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

  /// `Library`
  String get Calculator_library {
    return Intl.message(
      'Library',
      name: 'Calculator_library',
      desc: '',
      args: [],
    );
  }

  /// `{kind} library`
  String Calculator_material_library_title(Object kind) {
    return Intl.message(
      '$kind library',
      name: 'Calculator_material_library_title',
      desc: '',
      args: [kind],
    );
  }

  /// `Values fill in as {units}. Typical published data for preliminary design; check your supplier data sheets.`
  String Calculator_material_library_help(Object units) {
    return Intl.message(
      'Values fill in as $units. Typical published data for preliminary design; check your supplier data sheets.',
      name: 'Calculator_material_library_help',
      desc: '',
      args: [units],
    );
  }

  /// `Search materials`
  String get Calculator_search_materials {
    return Intl.message(
      'Search materials',
      name: 'Calculator_search_materials',
      desc: '',
      args: [],
    );
  }

  /// `Save current inputs as a material`
  String get Calculator_save_current_material {
    return Intl.message(
      'Save current inputs as a material',
      name: 'Calculator_save_current_material',
      desc: '',
      args: [],
    );
  }

  /// `My materials`
  String get Calculator_my_materials {
    return Intl.message(
      'My materials',
      name: 'Calculator_my_materials',
      desc: '',
      args: [],
    );
  }

  /// `Built-in`
  String get Calculator_built_in_materials {
    return Intl.message(
      'Built-in',
      name: 'Calculator_built_in_materials',
      desc: '',
      args: [],
    );
  }

  /// `No materials match your search.`
  String get Calculator_no_material_matches {
    return Intl.message(
      'No materials match your search.',
      name: 'Calculator_no_material_matches',
      desc: '',
      args: [],
    );
  }

  /// `Delete {name}`
  String Calculator_delete_material_tooltip(Object name) {
    return Intl.message(
      'Delete $name',
      name: 'Calculator_delete_material_tooltip',
      desc: '',
      args: [name],
    );
  }

  /// `Delete material?`
  String get Calculator_delete_material_title {
    return Intl.message(
      'Delete material?',
      name: 'Calculator_delete_material_title',
      desc: '',
      args: [],
    );
  }

  /// `"{name}" will be removed from your library.`
  String Calculator_delete_material_message(Object name) {
    return Intl.message(
      '"$name" will be removed from your library.',
      name: 'Calculator_delete_material_message',
      desc: '',
      args: [name],
    );
  }

  /// `Save material`
  String get Calculator_save_material_title {
    return Intl.message(
      'Save material',
      name: 'Calculator_save_material_title',
      desc: '',
      args: [],
    );
  }

  /// `Material name`
  String get Calculator_material_name {
    return Intl.message(
      'Material name',
      name: 'Calculator_material_name',
      desc: '',
      args: [],
    );
  }

  /// `Enter the elastic constants before saving.`
  String get Calculator_material_elastic_required {
    return Intl.message(
      'Enter the elastic constants before saving.',
      name: 'Calculator_material_elastic_required',
      desc: '',
      args: [],
    );
  }

  /// `Saved "{name}" to your library.`
  String Calculator_material_saved(Object name) {
    return Intl.message(
      'Saved "$name" to your library.',
      name: 'Calculator_material_saved',
      desc: '',
      args: [name],
    );
  }

  /// `Could not save this material. Check its values and try again.`
  String get Calculator_material_save_failed {
    return Intl.message(
      'Could not save this material. Check its values and try again.',
      name: 'Calculator_material_save_failed',
      desc: '',
      args: [],
    );
  }

  /// `Order`
  String get Calculator_material_order {
    return Intl.message(
      'Order',
      name: 'Calculator_material_order',
      desc: '',
      args: [],
    );
  }

  /// `Original order`
  String get Calculator_material_original_order {
    return Intl.message(
      'Original order',
      name: 'Calculator_material_original_order',
      desc: '',
      args: [],
    );
  }

  /// `Name (A–Z)`
  String get Calculator_material_alphabetical_order {
    return Intl.message(
      'Name (A–Z)',
      name: 'Calculator_material_alphabetical_order',
      desc: '',
      args: [],
    );
  }

  /// `View in table`
  String get Calculator_view_in_table {
    return Intl.message(
      'View in table',
      name: 'Calculator_view_in_table',
      desc: '',
      args: [],
    );
  }

  /// `Selected surface: ply {ply}, {surface}`
  String Calculator_focused_surface(int ply, String surface) {
    return Intl.message(
      'Selected surface: ply $ply, $surface',
      name: 'Calculator_focused_surface',
      desc: '',
      args: [ply, surface],
    );
  }

  /// `Jump to latest`
  String get Chat_jump_to_latest {
    return Intl.message(
      'Jump to latest',
      name: 'Chat_jump_to_latest',
      desc: '',
      args: [],
    );
  }

  /// `Preview {name}`
  String Chat_preview_image(Object name) {
    return Intl.message(
      'Preview $name',
      name: 'Chat_preview_image',
      desc: '',
      args: [name],
    );
  }

  /// `Image preview`
  String get Chat_image_preview {
    return Intl.message(
      'Image preview',
      name: 'Chat_image_preview',
      desc: '',
      args: [],
    );
  }

  /// `Image preview is unavailable.`
  String get Chat_image_preview_unavailable {
    return Intl.message(
      'Image preview is unavailable.',
      name: 'Chat_image_preview_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Close image preview`
  String get Chat_close_image_preview {
    return Intl.message(
      'Close image preview',
      name: 'Chat_close_image_preview',
      desc: '',
      args: [],
    );
  }

  /// `Remove {name}`
  String Chat_remove_attachment(Object name) {
    return Intl.message(
      'Remove $name',
      name: 'Chat_remove_attachment',
      desc: '',
      args: [name],
    );
  }

  /// `Chat`
  String get Chat_title {
    return Intl.message('Chat', name: 'Chat_title', desc: '', args: []);
  }

  /// `Cancel`
  String get Chat_cancel {
    return Intl.message('Cancel', name: 'Chat_cancel', desc: '', args: []);
  }

  /// `Save`
  String get Chat_save {
    return Intl.message('Save', name: 'Chat_save', desc: '', args: []);
  }

  /// `Delete`
  String get Chat_delete {
    return Intl.message('Delete', name: 'Chat_delete', desc: '', args: []);
  }

  /// `Clear`
  String get Chat_clear {
    return Intl.message('Clear', name: 'Chat_clear', desc: '', args: []);
  }

  /// `Clear search`
  String get Chat_clear_search {
    return Intl.message(
      'Clear search',
      name: 'Chat_clear_search',
      desc: '',
      args: [],
    );
  }

  /// `Sign In`
  String get Chat_sign_in {
    return Intl.message('Sign In', name: 'Chat_sign_in', desc: '', args: []);
  }

  /// `Composite Calculators`
  String get Chat_composite_calculators {
    return Intl.message(
      'Composite Calculators',
      name: 'Chat_composite_calculators',
      desc: '',
      args: [],
    );
  }

  /// `Account & settings`
  String get Chat_account_settings {
    return Intl.message(
      'Account & settings',
      name: 'Chat_account_settings',
      desc: '',
      args: [],
    );
  }

  /// `Composite expert`
  String get Chat_composite_expert {
    return Intl.message(
      'Composite expert',
      name: 'Chat_composite_expert',
      desc: '',
      args: [],
    );
  }

  /// `Export conversation`
  String get Chat_export_conversation {
    return Intl.message(
      'Export conversation',
      name: 'Chat_export_conversation',
      desc: '',
      args: [],
    );
  }

  /// `Share as Markdown`
  String get Chat_share_markdown {
    return Intl.message(
      'Share as Markdown',
      name: 'Chat_share_markdown',
      desc: '',
      args: [],
    );
  }

  /// `Share as PDF`
  String get Chat_share_pdf {
    return Intl.message(
      'Share as PDF',
      name: 'Chat_share_pdf',
      desc: '',
      args: [],
    );
  }

  /// `Could not export this conversation.`
  String get Chat_export_failed {
    return Intl.message(
      'Could not export this conversation.',
      name: 'Chat_export_failed',
      desc: '',
      args: [],
    );
  }

  /// `Ask about composites engineering…`
  String get Chat_composer_hint {
    return Intl.message(
      'Ask about composites engineering…',
      name: 'Chat_composer_hint',
      desc: '',
      args: [],
    );
  }

  /// `Voice input is unavailable. Please check microphone permissions.`
  String get Chat_voice_unavailable {
    return Intl.message(
      'Voice input is unavailable. Please check microphone permissions.',
      name: 'Chat_voice_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Stop generating`
  String get Chat_stop_generating {
    return Intl.message(
      'Stop generating',
      name: 'Chat_stop_generating',
      desc: '',
      args: [],
    );
  }

  /// `Generating response. Stop generating`
  String get Chat_generating_response_stop {
    return Intl.message(
      'Generating response. Stop generating',
      name: 'Chat_generating_response_stop',
      desc: '',
      args: [],
    );
  }

  /// `Stop voice input`
  String get Chat_stop_voice_input {
    return Intl.message(
      'Stop voice input',
      name: 'Chat_stop_voice_input',
      desc: '',
      args: [],
    );
  }

  /// `Send message`
  String get Chat_send_message {
    return Intl.message(
      'Send message',
      name: 'Chat_send_message',
      desc: '',
      args: [],
    );
  }

  /// `Start voice input`
  String get Chat_start_voice_input {
    return Intl.message(
      'Start voice input',
      name: 'Chat_start_voice_input',
      desc: '',
      args: [],
    );
  }

  /// `Add attachment`
  String get Chat_add_attachment {
    return Intl.message(
      'Add attachment',
      name: 'Chat_add_attachment',
      desc: '',
      args: [],
    );
  }

  /// `Select model`
  String get Chat_select_model {
    return Intl.message(
      'Select model',
      name: 'Chat_select_model',
      desc: '',
      args: [],
    );
  }

  /// `Models`
  String get Chat_models {
    return Intl.message('Models', name: 'Chat_models', desc: '', args: []);
  }

  /// `Photo Library`
  String get Chat_photo_library {
    return Intl.message(
      'Photo Library',
      name: 'Chat_photo_library',
      desc: '',
      args: [],
    );
  }

  /// `Camera`
  String get Chat_camera {
    return Intl.message('Camera', name: 'Chat_camera', desc: '', args: []);
  }

  /// `Files`
  String get Chat_files {
    return Intl.message('Files', name: 'Chat_files', desc: '', args: []);
  }

  /// `Knowledge`
  String get Chat_knowledge {
    return Intl.message(
      'Knowledge',
      name: 'Chat_knowledge',
      desc: '',
      args: [],
    );
  }

  /// `Attach RAG sources`
  String get Chat_attach_knowledge_sources {
    return Intl.message(
      'Attach RAG sources',
      name: 'Chat_attach_knowledge_sources',
      desc: '',
      args: [],
    );
  }

  /// `Refresh knowledge`
  String get Chat_refresh_knowledge {
    return Intl.message(
      'Refresh knowledge',
      name: 'Chat_refresh_knowledge',
      desc: '',
      args: [],
    );
  }

  /// `Search knowledge`
  String get Chat_search_knowledge {
    return Intl.message(
      'Search knowledge',
      name: 'Chat_search_knowledge',
      desc: '',
      args: [],
    );
  }

  /// `No knowledge sources found`
  String get Chat_no_knowledge_sources {
    return Intl.message(
      'No knowledge sources found',
      name: 'Chat_no_knowledge_sources',
      desc: '',
      args: [],
    );
  }

  /// `{count} files`
  String Chat_file_count(int count) {
    return Intl.message(
      '$count files',
      name: 'Chat_file_count',
      desc: '',
      args: [count],
    );
  }

  /// `Processing failed: {error}`
  String Chat_processing_failed_detail(String error) {
    return Intl.message(
      'Processing failed: $error',
      name: 'Chat_processing_failed_detail',
      desc: '',
      args: [error],
    );
  }

  /// `Processing failed`
  String get Chat_processing_failed {
    return Intl.message(
      'Processing failed',
      name: 'Chat_processing_failed',
      desc: '',
      args: [],
    );
  }

  /// `Processing document…`
  String get Chat_processing_document {
    return Intl.message(
      'Processing document…',
      name: 'Chat_processing_document',
      desc: '',
      args: [],
    );
  }

  /// `Read {name}`
  String Chat_read_file(String name) {
    return Intl.message(
      'Read $name',
      name: 'Chat_read_file',
      desc: '',
      args: [name],
    );
  }

  /// `{count, plural, one{{count} attachment} other{{count} attachments}}`
  String Chat_attachment_count(int count) {
    return Intl.plural(
      count,
      one: '$count attachment',
      other: '$count attachments',
      name: 'Chat_attachment_count',
      desc: '',
      args: [count],
    );
  }

  /// `Sign in to access chat, or use the composite calculators without signing in.`
  String get Chat_sign_in_description {
    return Intl.message(
      'Sign in to access chat, or use the composite calculators without signing in.',
      name: 'Chat_sign_in_description',
      desc: '',
      args: [],
    );
  }

  /// `Sign In to Chat`
  String get Chat_sign_in_to_chat {
    return Intl.message(
      'Sign In to Chat',
      name: 'Chat_sign_in_to_chat',
      desc: '',
      args: [],
    );
  }

  /// `Open Composite Calculators`
  String get Chat_open_calculators {
    return Intl.message(
      'Open Composite Calculators',
      name: 'Chat_open_calculators',
      desc: '',
      args: [],
    );
  }

  /// `Share chat`
  String get Chat_share_chat {
    return Intl.message(
      'Share chat',
      name: 'Chat_share_chat',
      desc: '',
      args: [],
    );
  }

  /// `Messages you send after creating your link won’t be shared. Anyone with the URL can view this chat.`
  String get Chat_share_chat_description {
    return Intl.message(
      'Messages you send after creating your link won’t be shared. Anyone with the URL can view this chat.',
      name: 'Chat_share_chat_description',
      desc: '',
      args: [],
    );
  }

  /// `Copy link`
  String get Chat_copy_link {
    return Intl.message(
      'Copy link',
      name: 'Chat_copy_link',
      desc: '',
      args: [],
    );
  }

  /// `Link copied to clipboard`
  String get Chat_link_copied {
    return Intl.message(
      'Link copied to clipboard',
      name: 'Chat_link_copied',
      desc: '',
      args: [],
    );
  }

  /// `Rename chat`
  String get Chat_rename_chat {
    return Intl.message(
      'Rename chat',
      name: 'Chat_rename_chat',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get Chat_chat_title {
    return Intl.message('Title', name: 'Chat_chat_title', desc: '', args: []);
  }

  /// `Delete chat?`
  String get Chat_delete_chat_title {
    return Intl.message(
      'Delete chat?',
      name: 'Chat_delete_chat_title',
      desc: '',
      args: [],
    );
  }

  /// `Delete “{name}”? This cannot be undone.`
  String Chat_delete_chat_message(String name) {
    return Intl.message(
      'Delete “$name”? This cannot be undone.',
      name: 'Chat_delete_chat_message',
      desc: '',
      args: [name],
    );
  }

  /// `Delete this chat? This cannot be undone.`
  String get Chat_delete_untitled_chat_message {
    return Intl.message(
      'Delete this chat? This cannot be undone.',
      name: 'Chat_delete_untitled_chat_message',
      desc: '',
      args: [],
    );
  }

  /// `Move to folder`
  String get Chat_move_to_folder {
    return Intl.message(
      'Move to folder',
      name: 'Chat_move_to_folder',
      desc: '',
      args: [],
    );
  }

  /// `New folder`
  String get Chat_new_folder {
    return Intl.message(
      'New folder',
      name: 'Chat_new_folder',
      desc: '',
      args: [],
    );
  }

  /// `Folder name`
  String get Chat_folder_name {
    return Intl.message(
      'Folder name',
      name: 'Chat_folder_name',
      desc: '',
      args: [],
    );
  }

  /// `Remove from folder`
  String get Chat_remove_from_folder {
    return Intl.message(
      'Remove from folder',
      name: 'Chat_remove_from_folder',
      desc: '',
      args: [],
    );
  }

  /// `No folders yet`
  String get Chat_no_folders {
    return Intl.message(
      'No folders yet',
      name: 'Chat_no_folders',
      desc: '',
      args: [],
    );
  }

  /// `Untitled chat`
  String get Chat_untitled_chat {
    return Intl.message(
      'Untitled chat',
      name: 'Chat_untitled_chat',
      desc: '',
      args: [],
    );
  }

  /// `Chat options`
  String get Chat_chat_options {
    return Intl.message(
      'Chat options',
      name: 'Chat_chat_options',
      desc: '',
      args: [],
    );
  }

  /// `Pin`
  String get Chat_pin {
    return Intl.message('Pin', name: 'Chat_pin', desc: '', args: []);
  }

  /// `Unpin`
  String get Chat_unpin {
    return Intl.message('Unpin', name: 'Chat_unpin', desc: '', args: []);
  }

  /// `Rename`
  String get Chat_rename {
    return Intl.message('Rename', name: 'Chat_rename', desc: '', args: []);
  }

  /// `Share`
  String get Chat_share {
    return Intl.message('Share', name: 'Chat_share', desc: '', args: []);
  }

  /// `Archive`
  String get Chat_archive {
    return Intl.message('Archive', name: 'Chat_archive', desc: '', args: []);
  }

  /// `No chats found`
  String get Chat_no_chats_found {
    return Intl.message(
      'No chats found',
      name: 'Chat_no_chats_found',
      desc: '',
      args: [],
    );
  }

  /// `No matching chats`
  String get Chat_no_matching_chats {
    return Intl.message(
      'No matching chats',
      name: 'Chat_no_matching_chats',
      desc: '',
      args: [],
    );
  }

  /// `No chats yet`
  String get Chat_no_chats {
    return Intl.message(
      'No chats yet',
      name: 'Chat_no_chats',
      desc: '',
      args: [],
    );
  }

  /// `Start a new chat to begin a conversation.`
  String get Chat_start_new_chat_help {
    return Intl.message(
      'Start a new chat to begin a conversation.',
      name: 'Chat_start_new_chat_help',
      desc: '',
      args: [],
    );
  }

  /// `Pinned`
  String get Chat_pinned {
    return Intl.message('Pinned', name: 'Chat_pinned', desc: '', args: []);
  }

  /// `Chats`
  String get Chat_chats {
    return Intl.message('Chats', name: 'Chat_chats', desc: '', args: []);
  }

  /// `No chats in folder`
  String get Chat_no_folder_chats {
    return Intl.message(
      'No chats in folder',
      name: 'Chat_no_folder_chats',
      desc: '',
      args: [],
    );
  }

  /// `Search chats`
  String get Chat_search_chats {
    return Intl.message(
      'Search chats',
      name: 'Chat_search_chats',
      desc: '',
      args: [],
    );
  }

  /// `Search "{query}"`
  String Chat_search_history_title(String query) {
    return Intl.message(
      'Search "$query"',
      name: 'Chat_search_history_title',
      desc: '',
      args: [query],
    );
  }

  /// `Archived`
  String get Chat_archived {
    return Intl.message('Archived', name: 'Chat_archived', desc: '', args: []);
  }

  /// `New chat`
  String get Chat_new_chat {
    return Intl.message('New chat', name: 'Chat_new_chat', desc: '', args: []);
  }

  /// `Welcome`
  String get Chat_welcome {
    return Intl.message('Welcome', name: 'Chat_welcome', desc: '', args: []);
  }

  /// `Welcome, {name}`
  String Chat_welcome_name(String name) {
    return Intl.message(
      'Welcome, $name',
      name: 'Chat_welcome_name',
      desc: '',
      args: [name],
    );
  }

  /// `Composites engineering copilot`
  String get Chat_engineering_copilot {
    return Intl.message(
      'Composites engineering copilot',
      name: 'Chat_engineering_copilot',
      desc: '',
      args: [],
    );
  }

  /// `What are you working on?`
  String get Chat_working_on {
    return Intl.message(
      'What are you working on?',
      name: 'Chat_working_on',
      desc: '',
      args: [],
    );
  }

  /// `Ask about materials, laminate design, failure analysis, manufacturing, or engineering calculations.`
  String get Chat_welcome_description {
    return Intl.message(
      'Ask about materials, laminate design, failure analysis, manufacturing, or engineering calculations.',
      name: 'Chat_welcome_description',
      desc: '',
      args: [],
    );
  }

  /// `Suggested questions`
  String get Chat_suggested_questions {
    return Intl.message(
      'Suggested questions',
      name: 'Chat_suggested_questions',
      desc: '',
      args: [],
    );
  }

  /// `Ask: {question}`
  String Chat_ask_question(String question) {
    return Intl.message(
      'Ask: $question',
      name: 'Chat_ask_question',
      desc: '',
      args: [question],
    );
  }

  /// `Copy message`
  String get Chat_copy_message {
    return Intl.message(
      'Copy message',
      name: 'Chat_copy_message',
      desc: '',
      args: [],
    );
  }

  /// `Copied`
  String get Chat_copied {
    return Intl.message('Copied', name: 'Chat_copied', desc: '', args: []);
  }

  /// `Get response`
  String get Chat_get_response {
    return Intl.message(
      'Get response',
      name: 'Chat_get_response',
      desc: '',
      args: [],
    );
  }

  /// `Regenerate response`
  String get Chat_regenerate_response {
    return Intl.message(
      'Regenerate response',
      name: 'Chat_regenerate_response',
      desc: '',
      args: [],
    );
  }

  /// `Good response`
  String get Chat_good_response {
    return Intl.message(
      'Good response',
      name: 'Chat_good_response',
      desc: '',
      args: [],
    );
  }

  /// `Bad response`
  String get Chat_bad_response {
    return Intl.message(
      'Bad response',
      name: 'Chat_bad_response',
      desc: '',
      args: [],
    );
  }

  /// `Edit positive feedback`
  String get Chat_edit_positive_feedback {
    return Intl.message(
      'Edit positive feedback',
      name: 'Chat_edit_positive_feedback',
      desc: '',
      args: [],
    );
  }

  /// `Edit negative feedback`
  String get Chat_edit_negative_feedback {
    return Intl.message(
      'Edit negative feedback',
      name: 'Chat_edit_negative_feedback',
      desc: '',
      args: [],
    );
  }

  /// `Feedback submitted`
  String get Chat_feedback_submitted {
    return Intl.message(
      'Feedback submitted',
      name: 'Chat_feedback_submitted',
      desc: '',
      args: [],
    );
  }

  /// `Knowledge file`
  String get Chat_knowledge_file {
    return Intl.message(
      'Knowledge file',
      name: 'Chat_knowledge_file',
      desc: '',
      args: [],
    );
  }

  /// `Knowledge collection`
  String get Chat_knowledge_collection {
    return Intl.message(
      'Knowledge collection',
      name: 'Chat_knowledge_collection',
      desc: '',
      args: [],
    );
  }

  /// `Response interrupted`
  String get Chat_response_interrupted {
    return Intl.message(
      'Response interrupted',
      name: 'Chat_response_interrupted',
      desc: '',
      args: [],
    );
  }

  /// `Use as draft`
  String get Chat_use_as_draft {
    return Intl.message(
      'Use as draft',
      name: 'Chat_use_as_draft',
      desc: '',
      args: [],
    );
  }

  /// `Replace draft?`
  String get Chat_replace_draft_title {
    return Intl.message(
      'Replace draft?',
      name: 'Chat_replace_draft_title',
      desc: '',
      args: [],
    );
  }

  /// `Replace the current unsent text with this message?`
  String get Chat_replace_draft_message {
    return Intl.message(
      'Replace the current unsent text with this message?',
      name: 'Chat_replace_draft_message',
      desc: '',
      args: [],
    );
  }

  /// `Replace draft`
  String get Chat_replace_draft {
    return Intl.message(
      'Replace draft',
      name: 'Chat_replace_draft',
      desc: '',
      args: [],
    );
  }

  /// `Find in chat`
  String get Chat_find_in_chat {
    return Intl.message(
      'Find in chat',
      name: 'Chat_find_in_chat',
      desc: '',
      args: [],
    );
  }

  /// `Search loaded messages`
  String get Chat_search_loaded_messages {
    return Intl.message(
      'Search loaded messages',
      name: 'Chat_search_loaded_messages',
      desc: '',
      args: [],
    );
  }

  /// `Enter text to search this conversation.`
  String get Chat_search_empty {
    return Intl.message(
      'Enter text to search this conversation.',
      name: 'Chat_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `No matching messages.`
  String get Chat_search_no_matches {
    return Intl.message(
      'No matching messages.',
      name: 'Chat_search_no_matches',
      desc: '',
      args: [],
    );
  }

  /// `{count} matching messages`
  String Chat_search_match_count(int count) {
    return Intl.message(
      '$count matching messages',
      name: 'Chat_search_match_count',
      desc: '',
      args: [count],
    );
  }

  /// `Copy excerpt`
  String get Chat_search_copy_excerpt {
    return Intl.message(
      'Copy excerpt',
      name: 'Chat_search_copy_excerpt',
      desc: '',
      args: [],
    );
  }

  /// `Excerpt copied`
  String get Chat_search_excerpt_copied {
    return Intl.message(
      'Excerpt copied',
      name: 'Chat_search_excerpt_copied',
      desc: '',
      args: [],
    );
  }

  /// `You`
  String get Chat_search_you {
    return Intl.message('You', name: 'Chat_search_you', desc: '', args: []);
  }

  /// `Assistant`
  String get Chat_search_assistant {
    return Intl.message(
      'Assistant',
      name: 'Chat_search_assistant',
      desc: '',
      args: [],
    );
  }

  /// `Clear search`
  String get Chat_search_clear {
    return Intl.message(
      'Clear search',
      name: 'Chat_search_clear',
      desc: '',
      args: [],
    );
  }

  /// `Could not copy this excerpt.`
  String get Chat_search_copy_failed {
    return Intl.message(
      'Could not copy this excerpt.',
      name: 'Chat_search_copy_failed',
      desc: '',
      args: [],
    );
  }

  /// `Rate this response`
  String get Chat_feedback_title {
    return Intl.message(
      'Rate this response',
      name: 'Chat_feedback_title',
      desc: '',
      args: [],
    );
  }

  /// `Your feedback helps improve answer quality.`
  String get Chat_feedback_help {
    return Intl.message(
      'Your feedback helps improve answer quality.',
      name: 'Chat_feedback_help',
      desc: '',
      args: [],
    );
  }

  /// `Helpful`
  String get Chat_feedback_helpful {
    return Intl.message(
      'Helpful',
      name: 'Chat_feedback_helpful',
      desc: '',
      args: [],
    );
  }

  /// `Needs work`
  String get Chat_feedback_needs_work {
    return Intl.message(
      'Needs work',
      name: 'Chat_feedback_needs_work',
      desc: '',
      args: [],
    );
  }

  /// `Quality score`
  String get Chat_feedback_quality_score {
    return Intl.message(
      'Quality score',
      name: 'Chat_feedback_quality_score',
      desc: '',
      args: [],
    );
  }

  /// `1 · Poor`
  String get Chat_feedback_poor {
    return Intl.message(
      '1 · Poor',
      name: 'Chat_feedback_poor',
      desc: '',
      args: [],
    );
  }

  /// `10 · Excellent`
  String get Chat_feedback_excellent {
    return Intl.message(
      '10 · Excellent',
      name: 'Chat_feedback_excellent',
      desc: '',
      args: [],
    );
  }

  /// `What influenced your rating?`
  String get Chat_feedback_reason_prompt {
    return Intl.message(
      'What influenced your rating?',
      name: 'Chat_feedback_reason_prompt',
      desc: '',
      args: [],
    );
  }

  /// `Additional details`
  String get Chat_feedback_additional_details {
    return Intl.message(
      'Additional details',
      name: 'Chat_feedback_additional_details',
      desc: '',
      args: [],
    );
  }

  /// `Optional`
  String get Chat_feedback_optional {
    return Intl.message(
      'Optional',
      name: 'Chat_feedback_optional',
      desc: '',
      args: [],
    );
  }

  /// `Select at least one reason to continue.`
  String get Chat_feedback_reason_required {
    return Intl.message(
      'Select at least one reason to continue.',
      name: 'Chat_feedback_reason_required',
      desc: '',
      args: [],
    );
  }

  /// `Feedback could not be saved. Try again.`
  String get Chat_feedback_save_failed {
    return Intl.message(
      'Feedback could not be saved. Try again.',
      name: 'Chat_feedback_save_failed',
      desc: '',
      args: [],
    );
  }

  /// `Submit feedback`
  String get Chat_feedback_submit {
    return Intl.message(
      'Submit feedback',
      name: 'Chat_feedback_submit',
      desc: '',
      args: [],
    );
  }

  /// `Update feedback`
  String get Chat_feedback_update {
    return Intl.message(
      'Update feedback',
      name: 'Chat_feedback_update',
      desc: '',
      args: [],
    );
  }

  /// `Feedback saved.`
  String get Chat_feedback_saved {
    return Intl.message(
      'Feedback saved.',
      name: 'Chat_feedback_saved',
      desc: '',
      args: [],
    );
  }

  /// `Accurate`
  String get Chat_feedback_accurate {
    return Intl.message(
      'Accurate',
      name: 'Chat_feedback_accurate',
      desc: '',
      args: [],
    );
  }

  /// `Clear explanation`
  String get Chat_feedback_clear_explanation {
    return Intl.message(
      'Clear explanation',
      name: 'Chat_feedback_clear_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Useful detail`
  String get Chat_feedback_useful_detail {
    return Intl.message(
      'Useful detail',
      name: 'Chat_feedback_useful_detail',
      desc: '',
      args: [],
    );
  }

  /// `Followed instructions`
  String get Chat_feedback_followed_instructions {
    return Intl.message(
      'Followed instructions',
      name: 'Chat_feedback_followed_instructions',
      desc: '',
      args: [],
    );
  }

  /// `Good structure`
  String get Chat_feedback_good_structure {
    return Intl.message(
      'Good structure',
      name: 'Chat_feedback_good_structure',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get Chat_feedback_other {
    return Intl.message(
      'Other',
      name: 'Chat_feedback_other',
      desc: '',
      args: [],
    );
  }

  /// `Inaccurate`
  String get Chat_feedback_inaccurate {
    return Intl.message(
      'Inaccurate',
      name: 'Chat_feedback_inaccurate',
      desc: '',
      args: [],
    );
  }

  /// `Unclear`
  String get Chat_feedback_unclear {
    return Intl.message(
      'Unclear',
      name: 'Chat_feedback_unclear',
      desc: '',
      args: [],
    );
  }

  /// `Too verbose`
  String get Chat_feedback_too_verbose {
    return Intl.message(
      'Too verbose',
      name: 'Chat_feedback_too_verbose',
      desc: '',
      args: [],
    );
  }

  /// `Not useful`
  String get Chat_feedback_not_useful {
    return Intl.message(
      'Not useful',
      name: 'Chat_feedback_not_useful',
      desc: '',
      args: [],
    );
  }

  /// `Didn't follow instructions`
  String get Chat_feedback_did_not_follow {
    return Intl.message(
      'Didn\'t follow instructions',
      name: 'Chat_feedback_did_not_follow',
      desc: '',
      args: [],
    );
  }

  /// `Copy code`
  String get Chat_copy_code {
    return Intl.message(
      'Copy code',
      name: 'Chat_copy_code',
      desc: '',
      args: [],
    );
  }

  /// `code`
  String get Chat_code {
    return Intl.message('code', name: 'Chat_code', desc: '', args: []);
  }

  /// `{language} - streaming`
  String Chat_code_streaming(String language) {
    return Intl.message(
      '$language - streaming',
      name: 'Chat_code_streaming',
      desc: '',
      args: [language],
    );
  }

  /// `Could not open this link.`
  String get Chat_open_link_failed {
    return Intl.message(
      'Could not open this link.',
      name: 'Chat_open_link_failed',
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
