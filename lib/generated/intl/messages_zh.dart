// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
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
  String get localeName => 'zh';

  static String m0(value, unit) => "深度：${value} ${unit}";

  static String m1(ply, surface) => "第 ${ply} 层 · ${surface}";

  static String m2(angles) => "铺层角度：${angles}";

  static String m3(unit) => "数值对于 ${unit} 过大，请检查单位";

  static String m4(count) => "另有 ${count} 层";

  static String m5(count) => "${count} 层";

  static String m6(value, unit) => "总厚度：${value} ${unit}";

  static String m7(modulus, stress, length, loads) =>
      "模量 ${modulus} · 应力 ${stress} · 长度 ${length} · 载荷 ${loads}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Angle_of_Rotation": MessageLookupByLibrary.simpleMessage("旋转角度"),
    "Anisotropic_material": MessageLookupByLibrary.simpleMessage("各向异性材料"),
    "Area": MessageLookupByLibrary.simpleMessage("面积"),
    "Buckling_Load": MessageLookupByLibrary.simpleMessage("屈曲载荷"),
    "Buckling_load_of_column": MessageLookupByLibrary.simpleMessage("杆的屈曲载荷计算"),
    "Calculate": MessageLookupByLibrary.simpleMessage("计算"),
    "Calculator_calculation_failed": MessageLookupByLibrary.simpleMessage(
      "无法计算结果，请检查材料常数、载荷和厚度。",
    ),
    "Calculator_chart_depth": m0,
    "Calculator_chart_inspection_hint": MessageLookupByLibrary.simpleMessage(
      "点击或悬停数据点以查看各层数值",
    ),
    "Calculator_chart_ply_surface": m1,
    "Calculator_clear_layup": MessageLookupByLibrary.simpleMessage("清除铺层次序"),
    "Calculator_copy_failed": MessageLookupByLibrary.simpleMessage(
      "无法复制结果，请重试。",
    ),
    "Calculator_copy_results": MessageLookupByLibrary.simpleMessage("复制结果"),
    "Calculator_expanded_angles": m2,
    "Calculator_export_failed": MessageLookupByLibrary.simpleMessage("无法导出结果。"),
    "Calculator_export_results": MessageLookupByLibrary.simpleMessage("导出结果"),
    "Calculator_finite_thickness": MessageLookupByLibrary.simpleMessage(
      "请输入有限数值",
    ),
    "Calculator_modulus_too_large": m3,
    "Calculator_more_plies": m4,
    "Calculator_ply_count": m5,
    "Calculator_poisson_range": MessageLookupByLibrary.simpleMessage(
      "必须介于 -1 和 0.5 之间",
    ),
    "Calculator_positive_number": MessageLookupByLibrary.simpleMessage("必须大于零"),
    "Calculator_positive_thickness": MessageLookupByLibrary.simpleMessage(
      "厚度必须大于零",
    ),
    "Calculator_results_copied": MessageLookupByLibrary.simpleMessage(
      "结果已复制到剪贴板",
    ),
    "Calculator_share_csv": MessageLookupByLibrary.simpleMessage("分享 CSV 文件"),
    "Calculator_share_pdf": MessageLookupByLibrary.simpleMessage("分享 PDF 文件"),
    "Calculator_si_name": MessageLookupByLibrary.simpleMessage("国际单位制（SI）"),
    "Calculator_surface_bottom": MessageLookupByLibrary.simpleMessage("底面"),
    "Calculator_surface_top": MessageLookupByLibrary.simpleMessage("顶面"),
    "Calculator_thickness": MessageLookupByLibrary.simpleMessage("厚度"),
    "Calculator_too_many_layers": MessageLookupByLibrary.simpleMessage(
      "铺层数量过多",
    ),
    "Calculator_total_thickness": m6,
    "Calculator_unit_details": m7,
    "Calculator_units": MessageLookupByLibrary.simpleMessage("计算器单位"),
    "Calculator_units_explanation": MessageLookupByLibrary.simpleMessage(
      "输入、结果和导出文件均使用这些单位。已输入的数值不会自动换算。",
    ),
    "Calculator_us_name": MessageLookupByLibrary.simpleMessage("美制单位"),
    "Calculator_volume_range": MessageLookupByLibrary.simpleMessage(
      "必须介于 0 和 1 之间",
    ),
    "Calculator_wrong_layup": MessageLookupByLibrary.simpleMessage("铺层次序无效"),
    "Compliance_Matrix_S": MessageLookupByLibrary.simpleMessage("柔度矩阵 S"),
    "Composite_Material": MessageLookupByLibrary.simpleMessage("复合材料力学"),
    "Constitutive_relation_of_linear_elastic_material":
        MessageLookupByLibrary.simpleMessage("线弹性材料的本构关系"),
    "CountdownDays": MessageLookupByLibrary.simpleMessage("日期倒计时"),
    "Deflection": MessageLookupByLibrary.simpleMessage("挠度"),
    "Deflections_and_slopes_of_cantilever_beams":
        MessageLookupByLibrary.simpleMessage("悬臂梁的挠度和斜率"),
    "Deflections_and_slopes_of_simple_beams":
        MessageLookupByLibrary.simpleMessage("简单梁的挠度和斜率"),
    "Description": MessageLookupByLibrary.simpleMessage("描述"),
    "Displacement": MessageLookupByLibrary.simpleMessage("位移"),
    "Engineering_Constants": MessageLookupByLibrary.simpleMessage("工程常数"),
    "Favorites": MessageLookupByLibrary.simpleMessage("收藏"),
    "Feedback": MessageLookupByLibrary.simpleMessage("反馈"),
    "FinanceGo": MessageLookupByLibrary.simpleMessage("美股财报通"),
    "Flexure_formula_of_beam": MessageLookupByLibrary.simpleMessage("梁的弯曲公式"),
    "Force": MessageLookupByLibrary.simpleMessage("力"),
    "Force_displacement_relation_of_bar": MessageLookupByLibrary.simpleMessage(
      "杆的力-位移关系",
    ),
    "General_stress_calculation": MessageLookupByLibrary.simpleMessage("应力计算"),
    "Inputs": MessageLookupByLibrary.simpleMessage("输入"),
    "Isotropic_material": MessageLookupByLibrary.simpleMessage("各向同性材料"),
    "Lamina_Constants": MessageLookupByLibrary.simpleMessage("单层板工程常数"),
    "Lamina_engineering_constants": MessageLookupByLibrary.simpleMessage(
      "单层板工程常数",
    ),
    "Lamina_stressstrain": MessageLookupByLibrary.simpleMessage("单层板应力/应变"),
    "Laminar_stressstrain": MessageLookupByLibrary.simpleMessage("层合板应力/应变"),
    "Laminate_3D_properties": MessageLookupByLibrary.simpleMessage("层合板 3D 属性"),
    "Laminate_plate_properties": MessageLookupByLibrary.simpleMessage(
      "层合板平面属性",
    ),
    "Layer_Thickness": MessageLookupByLibrary.simpleMessage("单层厚度"),
    "Layup_Angle": MessageLookupByLibrary.simpleMessage("铺层角"),
    "Layup_Sequence": MessageLookupByLibrary.simpleMessage("铺层次序"),
    "ME_Toolkit": MessageLookupByLibrary.simpleMessage("工程工具箱"),
    "Mechanics_of_Material": MessageLookupByLibrary.simpleMessage("材料力学"),
    "Moments_of_Inertia": MessageLookupByLibrary.simpleMessage("惯性矩"),
    "Moments_of_inertia_of_plane_areas": MessageLookupByLibrary.simpleMessage(
      "平面区域的惯性矩",
    ),
    "MoneyTracker": MessageLookupByLibrary.simpleMessage("极简记账"),
    "Monoclinic_material": MessageLookupByLibrary.simpleMessage("单斜材料"),
    "More": MessageLookupByLibrary.simpleMessage("更多"),
    "MoreApps": MessageLookupByLibrary.simpleMessage("更多应用"),
    "MyFavourite": MessageLookupByLibrary.simpleMessage("我的收藏"),
    "NASALover": MessageLookupByLibrary.simpleMessage("NASA迷"),
    "Not_a_number": MessageLookupByLibrary.simpleMessage("非数值"),
    "NovelsHub": MessageLookupByLibrary.simpleMessage("英文小说站"),
    "Orthotropic_material": MessageLookupByLibrary.simpleMessage("正交各向异性材料"),
    "Plane_Stresses": MessageLookupByLibrary.simpleMessage("平面应力"),
    "Plane_stresses_transformation": MessageLookupByLibrary.simpleMessage(
      "平面应力变换",
    ),
    "Principal_stresses_and_plane": MessageLookupByLibrary.simpleMessage(
      "主应力和平面",
    ),
    "RatethisApp": MessageLookupByLibrary.simpleMessage("给应用评分"),
    "Result": MessageLookupByLibrary.simpleMessage("结果"),
    "Result_Precision": MessageLookupByLibrary.simpleMessage("结果精度"),
    "Result_Strain": MessageLookupByLibrary.simpleMessage("应变结果"),
    "Result_Stress": MessageLookupByLibrary.simpleMessage("应力结果"),
    "Results": MessageLookupByLibrary.simpleMessage("结果"),
    "Settings": MessageLookupByLibrary.simpleMessage("设置"),
    "SharethisApp": MessageLookupByLibrary.simpleMessage("分享应用"),
    "Slope": MessageLookupByLibrary.simpleMessage("斜率"),
    "Stiffness_Matrix_C": MessageLookupByLibrary.simpleMessage("刚度矩阵 C"),
    "Stiffness_Matrix_Q": MessageLookupByLibrary.simpleMessage("刚度矩阵 Q"),
    "Strain": MessageLookupByLibrary.simpleMessage("应变"),
    "Stress": MessageLookupByLibrary.simpleMessage("应力"),
    "Stresses_in_a_thin_walled_cylindrical_pressure_vessel":
        MessageLookupByLibrary.simpleMessage("薄壁圆柱形压力容器中的应力"),
    "Stresses_in_the_wall_of_a_spherical_shell":
        MessageLookupByLibrary.simpleMessage("球壳壁中的应力"),
    "Stressstrain_of_linear_elastic_material":
        MessageLookupByLibrary.simpleMessage("线弹性材料的应力/应变"),
    "The_Maximum_Shear_Stress": MessageLookupByLibrary.simpleMessage("最大切应力"),
    "Theory_of_Elasticity": MessageLookupByLibrary.simpleMessage("弹性力学"),
    "Torsion_formula_of_bar": MessageLookupByLibrary.simpleMessage("杆的扭力公式"),
    "Transversely_isotropic_material": MessageLookupByLibrary.simpleMessage(
      "横向各向同性材料",
    ),
    "UDFRC_Properties": MessageLookupByLibrary.simpleMessage("单向纤维复合材料属性"),
  };
}
