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

  static String m0(value, unit) => "深度：${value} ${unit}";

  static String m1(ply, surface) => "第 ${ply} 層 · ${surface}";

  static String m2(name) => "「${name}」將從材料庫中移除。";

  static String m3(name) => "刪除 ${name}";

  static String m4(angles) => "鋪層角度：${angles}";

  static String m5(shown, total) => "已顯示 ${shown} / ${total} 個表面。匯出包括所有表面。";

  static String m6(ply, surface) => "選取的表面：第 ${ply} 層，${surface}";

  static String m7(units) => "數值將以 ${units} 填入。典型公開資料僅供初步設計參考，請核對供應商資料表。";

  static String m8(kind) => "${kind}材料庫";

  static String m9(name) => "已將「${name}」儲存至材料庫。";

  static String m10(unit) => "數值對於 ${unit} 過大，請檢查單位";

  static String m11(count) => "另有 ${count} 層";

  static String m12(count) => "${count} 層";

  static String m13(name) => "已存在名為「${name}」的材料。您可以取代其已儲存的資料，或選擇其他名稱。";

  static String m14(value, unit) => "總厚度：${value} ${unit}";

  static String m15(modulus, stress, length, loads) =>
      "模量 ${modulus} · 應力 ${stress} · 長度 ${length} · 載荷 ${loads}";

  static String m16(name) => "預覽 ${name}";

  static String m17(name) => "移除 ${name}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Angle_of_Rotation": MessageLookupByLibrary.simpleMessage("旋轉角度"),
    "Anisotropic_material": MessageLookupByLibrary.simpleMessage("各向異性材料"),
    "Area": MessageLookupByLibrary.simpleMessage("面積"),
    "Buckling_Load": MessageLookupByLibrary.simpleMessage("屈曲載荷"),
    "Buckling_load_of_column": MessageLookupByLibrary.simpleMessage("桿的屈曲載荷計算"),
    "Calculate": MessageLookupByLibrary.simpleMessage("計算"),
    "Calculator_all_failure_criteria": MessageLookupByLibrary.simpleMessage(
      "所有準則",
    ),
    "Calculator_apply_material": MessageLookupByLibrary.simpleMessage("套用材料"),
    "Calculator_built_in_materials": MessageLookupByLibrary.simpleMessage(
      "內置材料",
    ),
    "Calculator_calculation_failed": MessageLookupByLibrary.simpleMessage(
      "無法計算結果，請檢查材料常數、載荷和厚度。",
    ),
    "Calculator_chart_depth": m0,
    "Calculator_chart_inspection_hint": MessageLookupByLibrary.simpleMessage(
      "點選或懸停資料點以查看各層數值",
    ),
    "Calculator_chart_ply_surface": m1,
    "Calculator_choose_another_name": MessageLookupByLibrary.simpleMessage(
      "選擇其他名稱",
    ),
    "Calculator_clear_layup": MessageLookupByLibrary.simpleMessage("清除鋪層次序"),
    "Calculator_copy_failed": MessageLookupByLibrary.simpleMessage(
      "無法複製結果，請重試。",
    ),
    "Calculator_copy_results": MessageLookupByLibrary.simpleMessage("複製結果"),
    "Calculator_delete_material_message": m2,
    "Calculator_delete_material_title": MessageLookupByLibrary.simpleMessage(
      "刪除材料？",
    ),
    "Calculator_delete_material_tooltip": m3,
    "Calculator_expanded_angles": m4,
    "Calculator_export_failed": MessageLookupByLibrary.simpleMessage("無法匯出結果。"),
    "Calculator_export_materials": MessageLookupByLibrary.simpleMessage(
      "匯出我的材料（JSON）",
    ),
    "Calculator_export_materials_help": MessageLookupByLibrary.simpleMessage(
      "匯出所有已儲存的材料，數值使用 SI 單位，包括目前搜尋結果以外的材料。",
    ),
    "Calculator_export_results": MessageLookupByLibrary.simpleMessage("匯出結果"),
    "Calculator_failed_surfaces_only": MessageLookupByLibrary.simpleMessage(
      "只顯示失效表面",
    ),
    "Calculator_failure_criterion": MessageLookupByLibrary.simpleMessage("準則"),
    "Calculator_failure_exports_all": MessageLookupByLibrary.simpleMessage(
      "匯出一律包含所有表面及失效準則。",
    ),
    "Calculator_failure_filter_summary": m5,
    "Calculator_finite_thickness": MessageLookupByLibrary.simpleMessage(
      "請輸入有限數值",
    ),
    "Calculator_focused_surface": m6,
    "Calculator_library": MessageLookupByLibrary.simpleMessage("材料庫"),
    "Calculator_material_alphabetical_order":
        MessageLookupByLibrary.simpleMessage("名稱（A–Z）"),
    "Calculator_material_delete_failed": MessageLookupByLibrary.simpleMessage(
      "無法刪除此材料，請重試。",
    ),
    "Calculator_material_details": MessageLookupByLibrary.simpleMessage("材料詳情"),
    "Calculator_material_elastic_properties":
        MessageLookupByLibrary.simpleMessage("彈性性質"),
    "Calculator_material_elastic_required":
        MessageLookupByLibrary.simpleMessage("請先輸入彈性常數，再儲存材料。"),
    "Calculator_material_export_empty": MessageLookupByLibrary.simpleMessage(
      "儲存自訂材料後即可匯出 JSON。",
    ),
    "Calculator_material_export_failed": MessageLookupByLibrary.simpleMessage(
      "無法匯出已儲存的材料，請重試。",
    ),
    "Calculator_material_kind_fiber": MessageLookupByLibrary.simpleMessage(
      "纖維",
    ),
    "Calculator_material_kind_lamina": MessageLookupByLibrary.simpleMessage(
      "單向複合材料層",
    ),
    "Calculator_material_kind_matrix": MessageLookupByLibrary.simpleMessage(
      "基體",
    ),
    "Calculator_material_library_help": m7,
    "Calculator_material_library_title": m8,
    "Calculator_material_missing_note": MessageLookupByLibrary.simpleMessage(
      "未提供的彈性數值將保留目前輸入。未提供的熱膨脹或強度資料組亦會保留目前輸入。",
    ),
    "Calculator_material_name": MessageLookupByLibrary.simpleMessage("材料名稱"),
    "Calculator_material_not_provided": MessageLookupByLibrary.simpleMessage(
      "未提供",
    ),
    "Calculator_material_order": MessageLookupByLibrary.simpleMessage("排序"),
    "Calculator_material_original_order": MessageLookupByLibrary.simpleMessage(
      "原有次序",
    ),
    "Calculator_material_save_failed": MessageLookupByLibrary.simpleMessage(
      "無法儲存此材料，請檢查數值後重試。",
    ),
    "Calculator_material_saved": m9,
    "Calculator_material_source": MessageLookupByLibrary.simpleMessage("來源"),
    "Calculator_material_strengths": MessageLookupByLibrary.simpleMessage("強度"),
    "Calculator_material_strengths_note": MessageLookupByLibrary.simpleMessage(
      "只有五項強度數值全部提供時，才會一併套用強度數值。",
    ),
    "Calculator_material_thermal_note": MessageLookupByLibrary.simpleMessage(
      "套用熱膨脹係數需要提供 α11（各向同性材料為 α）。對於複合材料層及纖維，未提供的 α22 使用 α11，剪切熱膨脹係數設為零。",
    ),
    "Calculator_material_thermal_properties":
        MessageLookupByLibrary.simpleMessage("熱膨脹係數"),
    "Calculator_material_type": MessageLookupByLibrary.simpleMessage("材料類型"),
    "Calculator_modulus_too_large": m10,
    "Calculator_more_plies": m11,
    "Calculator_my_materials": MessageLookupByLibrary.simpleMessage("我的材料"),
    "Calculator_no_failed_surfaces": MessageLookupByLibrary.simpleMessage(
      "沒有符合此準則的失效表面。",
    ),
    "Calculator_no_failure_results": MessageLookupByLibrary.simpleMessage(
      "暫無失效分析結果。",
    ),
    "Calculator_no_material_matches": MessageLookupByLibrary.simpleMessage(
      "沒有符合搜尋條件的材料。",
    ),
    "Calculator_ply_count": m12,
    "Calculator_poisson_range": MessageLookupByLibrary.simpleMessage(
      "必須介於 -1 和 0.5 之間",
    ),
    "Calculator_positive_number": MessageLookupByLibrary.simpleMessage("必須大於零"),
    "Calculator_positive_thickness": MessageLookupByLibrary.simpleMessage(
      "厚度必須大於零",
    ),
    "Calculator_replace_material": MessageLookupByLibrary.simpleMessage("取代"),
    "Calculator_replace_material_message": m13,
    "Calculator_replace_material_title": MessageLookupByLibrary.simpleMessage(
      "取代已儲存的材料？",
    ),
    "Calculator_results_copied": MessageLookupByLibrary.simpleMessage(
      "結果已複製到剪貼簿",
    ),
    "Calculator_save_current_material": MessageLookupByLibrary.simpleMessage(
      "將目前輸入儲存為材料",
    ),
    "Calculator_save_material_title": MessageLookupByLibrary.simpleMessage(
      "儲存材料",
    ),
    "Calculator_search_materials": MessageLookupByLibrary.simpleMessage("搜尋材料"),
    "Calculator_share_csv": MessageLookupByLibrary.simpleMessage("分享 CSV 檔案"),
    "Calculator_share_pdf": MessageLookupByLibrary.simpleMessage("分享 PDF 檔案"),
    "Calculator_si_name": MessageLookupByLibrary.simpleMessage("國際單位制（SI）"),
    "Calculator_surface_bottom": MessageLookupByLibrary.simpleMessage("底面"),
    "Calculator_surface_top": MessageLookupByLibrary.simpleMessage("頂面"),
    "Calculator_thickness": MessageLookupByLibrary.simpleMessage("厚度"),
    "Calculator_too_many_layers": MessageLookupByLibrary.simpleMessage(
      "鋪層數量過多",
    ),
    "Calculator_total_thickness": m14,
    "Calculator_unit_details": m15,
    "Calculator_units": MessageLookupByLibrary.simpleMessage("計算器單位"),
    "Calculator_units_explanation": MessageLookupByLibrary.simpleMessage(
      "輸入、結果和匯出檔案均使用這些單位。已輸入的數值不會自動換算。",
    ),
    "Calculator_us_name": MessageLookupByLibrary.simpleMessage("美制單位"),
    "Calculator_view_in_table": MessageLookupByLibrary.simpleMessage("在表格中檢視"),
    "Calculator_volume_range": MessageLookupByLibrary.simpleMessage(
      "必須介於 0 和 1 之間",
    ),
    "Calculator_wrong_layup": MessageLookupByLibrary.simpleMessage("鋪層次序無效"),
    "Chat_close_image_preview": MessageLookupByLibrary.simpleMessage("關閉圖片預覽"),
    "Chat_image_preview": MessageLookupByLibrary.simpleMessage("圖片預覽"),
    "Chat_image_preview_unavailable": MessageLookupByLibrary.simpleMessage(
      "無法預覽此圖片。",
    ),
    "Chat_jump_to_latest": MessageLookupByLibrary.simpleMessage("跳至最新訊息"),
    "Chat_preview_image": m16,
    "Chat_remove_attachment": m17,
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
