// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_HK locale. All the
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
  String get localeName => 'zh_HK';

  static String m0(angles) => "鋪層角度：${angles}";

  static String m1(unit) => "數值對於 ${unit} 過大，請檢查單位";

  static String m2(count) => "另有 ${count} 層";

  static String m3(count) => "${count} 層";

  static String m4(value, unit) => "總厚度：${value} ${unit}";

  static String m5(modulus, stress, length, loads) =>
      "模量 ${modulus} · 應力 ${stress} · 長度 ${length} · 載荷 ${loads}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Angle_of_Rotation": MessageLookupByLibrary.simpleMessage("旋轉角度"),
    "Anisotropic_material": MessageLookupByLibrary.simpleMessage("各向異性材料"),
    "Area": MessageLookupByLibrary.simpleMessage("面積"),
    "Buckling_Load": MessageLookupByLibrary.simpleMessage("屈曲載荷"),
    "Buckling_load_of_column": MessageLookupByLibrary.simpleMessage("桿的屈曲載荷計算"),
    "Calculate": MessageLookupByLibrary.simpleMessage("計算"),
    "Calculator_calculation_failed": MessageLookupByLibrary.simpleMessage(
      "無法計算結果，請檢查材料常數、載荷和厚度。",
    ),
    "Calculator_clear_layup": MessageLookupByLibrary.simpleMessage("清除鋪層次序"),
    "Calculator_copy_failed": MessageLookupByLibrary.simpleMessage(
      "無法複製結果，請重試。",
    ),
    "Calculator_copy_results": MessageLookupByLibrary.simpleMessage("複製結果"),
    "Calculator_expanded_angles": m0,
    "Calculator_export_failed": MessageLookupByLibrary.simpleMessage("無法匯出結果。"),
    "Calculator_export_results": MessageLookupByLibrary.simpleMessage("匯出結果"),
    "Calculator_finite_thickness": MessageLookupByLibrary.simpleMessage(
      "請輸入有限數值",
    ),
    "Calculator_modulus_too_large": m1,
    "Calculator_more_plies": m2,
    "Calculator_ply_count": m3,
    "Calculator_poisson_range": MessageLookupByLibrary.simpleMessage(
      "必須介於 -1 和 0.5 之間",
    ),
    "Calculator_positive_number": MessageLookupByLibrary.simpleMessage("必須大於零"),
    "Calculator_positive_thickness": MessageLookupByLibrary.simpleMessage(
      "厚度必須大於零",
    ),
    "Calculator_results_copied": MessageLookupByLibrary.simpleMessage(
      "結果已複製到剪貼簿",
    ),
    "Calculator_share_csv": MessageLookupByLibrary.simpleMessage("分享 CSV 檔案"),
    "Calculator_share_pdf": MessageLookupByLibrary.simpleMessage("分享 PDF 檔案"),
    "Calculator_si_name": MessageLookupByLibrary.simpleMessage("國際單位制（SI）"),
    "Calculator_thickness": MessageLookupByLibrary.simpleMessage("厚度"),
    "Calculator_too_many_layers": MessageLookupByLibrary.simpleMessage(
      "鋪層數量過多",
    ),
    "Calculator_total_thickness": m4,
    "Calculator_unit_details": m5,
    "Calculator_units": MessageLookupByLibrary.simpleMessage("計算器單位"),
    "Calculator_units_explanation": MessageLookupByLibrary.simpleMessage(
      "輸入、結果和匯出檔案均使用這些單位。已輸入的數值不會自動換算。",
    ),
    "Calculator_us_name": MessageLookupByLibrary.simpleMessage("美制單位"),
    "Calculator_volume_range": MessageLookupByLibrary.simpleMessage(
      "必須介於 0 和 1 之間",
    ),
    "Calculator_wrong_layup": MessageLookupByLibrary.simpleMessage("鋪層次序無效"),
    "Compliance_Matrix_S": MessageLookupByLibrary.simpleMessage("柔度矩陣 S"),
    "Composite_Material": MessageLookupByLibrary.simpleMessage("複合材料力學"),
    "Constitutive_relation_of_linear_elastic_material":
        MessageLookupByLibrary.simpleMessage("線彈性材料的本構關係"),
    "CountdownDays": MessageLookupByLibrary.simpleMessage("日期倒計時"),
    "Deflection": MessageLookupByLibrary.simpleMessage("撓度"),
    "Deflections_and_slopes_of_cantilever_beams":
        MessageLookupByLibrary.simpleMessage("懸臂樑的撓度和斜率"),
    "Deflections_and_slopes_of_simple_beams":
        MessageLookupByLibrary.simpleMessage("簡單樑的撓度和斜率"),
    "Description": MessageLookupByLibrary.simpleMessage("描述"),
    "Displacement": MessageLookupByLibrary.simpleMessage("位移"),
    "Engineering_Constants": MessageLookupByLibrary.simpleMessage("工程常數"),
    "Favorites": MessageLookupByLibrary.simpleMessage("收藏"),
    "Feedback": MessageLookupByLibrary.simpleMessage("反饋"),
    "FinanceGo": MessageLookupByLibrary.simpleMessage("美股財報通"),
    "Flexure_formula_of_beam": MessageLookupByLibrary.simpleMessage("樑的彎曲公式"),
    "Force": MessageLookupByLibrary.simpleMessage("力"),
    "Force_displacement_relation_of_bar": MessageLookupByLibrary.simpleMessage(
      "桿的力-位移關係",
    ),
    "General_stress_calculation": MessageLookupByLibrary.simpleMessage("應力計算"),
    "Inputs": MessageLookupByLibrary.simpleMessage("輸入"),
    "Isotropic_material": MessageLookupByLibrary.simpleMessage("各向同性材料"),
    "Lamina_Constants": MessageLookupByLibrary.simpleMessage("單層板工程常數"),
    "Lamina_engineering_constants": MessageLookupByLibrary.simpleMessage(
      "單層板工程常數",
    ),
    "Lamina_stressstrain": MessageLookupByLibrary.simpleMessage("單層板應力/應變"),
    "Laminar_stressstrain": MessageLookupByLibrary.simpleMessage("層合板應力/應變"),
    "Laminate_3D_properties": MessageLookupByLibrary.simpleMessage("層合板 3D 屬性"),
    "Laminate_plate_properties": MessageLookupByLibrary.simpleMessage(
      "層合板平面屬性",
    ),
    "Layer_Thickness": MessageLookupByLibrary.simpleMessage("單層厚度"),
    "Layup_Angle": MessageLookupByLibrary.simpleMessage("鋪層角"),
    "Layup_Sequence": MessageLookupByLibrary.simpleMessage("鋪層次序"),
    "ME_Toolkit": MessageLookupByLibrary.simpleMessage("工程工具箱"),
    "Mechanics_of_Material": MessageLookupByLibrary.simpleMessage("材料力學"),
    "Moments_of_Inertia": MessageLookupByLibrary.simpleMessage("慣性矩"),
    "Moments_of_inertia_of_plane_areas": MessageLookupByLibrary.simpleMessage(
      "平面區域的慣性矩",
    ),
    "MoneyTracker": MessageLookupByLibrary.simpleMessage("極簡記賬"),
    "Monoclinic_material": MessageLookupByLibrary.simpleMessage("單斜材料"),
    "More": MessageLookupByLibrary.simpleMessage("更多"),
    "MoreApps": MessageLookupByLibrary.simpleMessage("更多應用"),
    "MyFavourite": MessageLookupByLibrary.simpleMessage("我的收藏"),
    "NASALover": MessageLookupByLibrary.simpleMessage("NASA迷"),
    "Not_a_number": MessageLookupByLibrary.simpleMessage("非數值"),
    "NovelsHub": MessageLookupByLibrary.simpleMessage("英文小說站"),
    "Orthotropic_material": MessageLookupByLibrary.simpleMessage("正交各向異性材料"),
    "Plane_Stresses": MessageLookupByLibrary.simpleMessage("平面應力"),
    "Plane_stresses_transformation": MessageLookupByLibrary.simpleMessage(
      "平面應力變換",
    ),
    "Principal_stresses_and_plane": MessageLookupByLibrary.simpleMessage(
      "主應力和平面",
    ),
    "RatethisApp": MessageLookupByLibrary.simpleMessage("給應用評分"),
    "Result": MessageLookupByLibrary.simpleMessage("結果"),
    "Result_Precision": MessageLookupByLibrary.simpleMessage("結果精度"),
    "Result_Strain": MessageLookupByLibrary.simpleMessage("應變結果"),
    "Result_Stress": MessageLookupByLibrary.simpleMessage("應力結果"),
    "Results": MessageLookupByLibrary.simpleMessage("結果"),
    "Settings": MessageLookupByLibrary.simpleMessage("設置"),
    "SharethisApp": MessageLookupByLibrary.simpleMessage("分享應用"),
    "Slope": MessageLookupByLibrary.simpleMessage("斜率"),
    "Stiffness_Matrix_C": MessageLookupByLibrary.simpleMessage("剛度矩陣 C"),
    "Stiffness_Matrix_Q": MessageLookupByLibrary.simpleMessage("剛度矩陣 Q"),
    "Strain": MessageLookupByLibrary.simpleMessage("應變"),
    "Stress": MessageLookupByLibrary.simpleMessage("應力"),
    "Stresses_in_a_thin_walled_cylindrical_pressure_vessel":
        MessageLookupByLibrary.simpleMessage("薄壁圓柱形壓力容器中的應力"),
    "Stresses_in_the_wall_of_a_spherical_shell":
        MessageLookupByLibrary.simpleMessage("球殼壁中的應力"),
    "Stressstrain_of_linear_elastic_material":
        MessageLookupByLibrary.simpleMessage("線彈性材料的應力/應變"),
    "The_Maximum_Shear_Stress": MessageLookupByLibrary.simpleMessage("最大切應力"),
    "Theory_of_Elasticity": MessageLookupByLibrary.simpleMessage("彈性力學"),
    "Torsion_formula_of_bar": MessageLookupByLibrary.simpleMessage("桿的扭力公式"),
    "Transversely_isotropic_material": MessageLookupByLibrary.simpleMessage(
      "橫向各向同性材料",
    ),
    "UDFRC_Properties": MessageLookupByLibrary.simpleMessage("單向纖維複合材料屬性"),
  };
}
