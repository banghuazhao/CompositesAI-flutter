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

  static String m16(question) => "提問：${question}";

  static String m17(count) => "${count} 個附件";

  static String m18(language) => "${language} - 生成中";

  static String m19(name) => "刪除「${name}」？此操作無法還原。";

  static String m20(count) => "${count} 個檔案";

  static String m21(dateTime) => "訊息時間：${dateTime}";

  static String m22(name) => "預覽 ${name}";

  static String m23(error) => "處理失敗：${error}";

  static String m24(name) => "閱讀 ${name}";

  static String m25(name) => "移除 ${name}";

  static String m26(query) => "搜尋「${query}」";

  static String m27(count) => "${count} 則符合的訊息";

  static String m28(name) => "歡迎，${name}";

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
    "Chat_account_settings": MessageLookupByLibrary.simpleMessage("帳戶與設定"),
    "Chat_add_attachment": MessageLookupByLibrary.simpleMessage("加入附件"),
    "Chat_archive": MessageLookupByLibrary.simpleMessage("封存"),
    "Chat_archived": MessageLookupByLibrary.simpleMessage("已封存"),
    "Chat_ask_question": m16,
    "Chat_attach_knowledge_sources": MessageLookupByLibrary.simpleMessage(
      "加入 RAG 來源",
    ),
    "Chat_attachment_count": m17,
    "Chat_bad_response": MessageLookupByLibrary.simpleMessage("不佳回覆"),
    "Chat_camera": MessageLookupByLibrary.simpleMessage("相機"),
    "Chat_cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "Chat_chat_options": MessageLookupByLibrary.simpleMessage("對話選項"),
    "Chat_chat_title": MessageLookupByLibrary.simpleMessage("標題"),
    "Chat_chats": MessageLookupByLibrary.simpleMessage("對話"),
    "Chat_clear": MessageLookupByLibrary.simpleMessage("清除"),
    "Chat_clear_draft": MessageLookupByLibrary.simpleMessage("清空草稿"),
    "Chat_clear_search": MessageLookupByLibrary.simpleMessage("清除搜尋"),
    "Chat_close_image_preview": MessageLookupByLibrary.simpleMessage("關閉圖片預覽"),
    "Chat_code": MessageLookupByLibrary.simpleMessage("程式碼"),
    "Chat_code_copy_failed": MessageLookupByLibrary.simpleMessage("無法複製此程式碼。"),
    "Chat_code_streaming": m18,
    "Chat_collapse_answer": MessageLookupByLibrary.simpleMessage("收起回答"),
    "Chat_composer_done": MessageLookupByLibrary.simpleMessage("完成"),
    "Chat_composer_hint": MessageLookupByLibrary.simpleMessage("詢問複合材料工程問題…"),
    "Chat_composite_calculators": MessageLookupByLibrary.simpleMessage(
      "複合材料計算器",
    ),
    "Chat_composite_expert": MessageLookupByLibrary.simpleMessage("複合材料專家"),
    "Chat_copied": MessageLookupByLibrary.simpleMessage("已複製"),
    "Chat_copy_code": MessageLookupByLibrary.simpleMessage("複製程式碼"),
    "Chat_copy_exchange": MessageLookupByLibrary.simpleMessage("複製問題和回答"),
    "Chat_copy_link": MessageLookupByLibrary.simpleMessage("複製連結"),
    "Chat_copy_message": MessageLookupByLibrary.simpleMessage("複製訊息"),
    "Chat_delete": MessageLookupByLibrary.simpleMessage("刪除"),
    "Chat_delete_chat_message": m19,
    "Chat_delete_chat_title": MessageLookupByLibrary.simpleMessage("刪除對話？"),
    "Chat_delete_untitled_chat_message": MessageLookupByLibrary.simpleMessage(
      "刪除此對話？此操作無法還原。",
    ),
    "Chat_draft": MessageLookupByLibrary.simpleMessage("草稿"),
    "Chat_draft_cleared": MessageLookupByLibrary.simpleMessage("已清空草稿。"),
    "Chat_edit_negative_feedback": MessageLookupByLibrary.simpleMessage(
      "編輯負面意見",
    ),
    "Chat_edit_positive_feedback": MessageLookupByLibrary.simpleMessage(
      "編輯正面意見",
    ),
    "Chat_engineering_copilot": MessageLookupByLibrary.simpleMessage(
      "複合材料工程助手",
    ),
    "Chat_exchange_answer": MessageLookupByLibrary.simpleMessage("回答"),
    "Chat_exchange_copied": MessageLookupByLibrary.simpleMessage("已複製問題和回答"),
    "Chat_exchange_copy_failed": MessageLookupByLibrary.simpleMessage(
      "無法複製這組問答。",
    ),
    "Chat_exchange_question": MessageLookupByLibrary.simpleMessage("問題"),
    "Chat_expand_answer": MessageLookupByLibrary.simpleMessage("展開回答"),
    "Chat_expand_composer": MessageLookupByLibrary.simpleMessage("展開輸入框"),
    "Chat_expanded_composer": MessageLookupByLibrary.simpleMessage("編輯問題"),
    "Chat_export_conversation": MessageLookupByLibrary.simpleMessage("匯出對話"),
    "Chat_export_failed": MessageLookupByLibrary.simpleMessage("無法匯出此對話。"),
    "Chat_feedback_accurate": MessageLookupByLibrary.simpleMessage("準確"),
    "Chat_feedback_additional_details": MessageLookupByLibrary.simpleMessage(
      "補充說明",
    ),
    "Chat_feedback_clear_explanation": MessageLookupByLibrary.simpleMessage(
      "解釋清晰",
    ),
    "Chat_feedback_did_not_follow": MessageLookupByLibrary.simpleMessage(
      "未遵循指示",
    ),
    "Chat_feedback_excellent": MessageLookupByLibrary.simpleMessage("10 · 優秀"),
    "Chat_feedback_followed_instructions": MessageLookupByLibrary.simpleMessage(
      "遵循了指示",
    ),
    "Chat_feedback_good_structure": MessageLookupByLibrary.simpleMessage(
      "結構良好",
    ),
    "Chat_feedback_help": MessageLookupByLibrary.simpleMessage("您的意見有助改善回答質素。"),
    "Chat_feedback_helpful": MessageLookupByLibrary.simpleMessage("有幫助"),
    "Chat_feedback_inaccurate": MessageLookupByLibrary.simpleMessage("不準確"),
    "Chat_feedback_needs_work": MessageLookupByLibrary.simpleMessage("需要改善"),
    "Chat_feedback_not_useful": MessageLookupByLibrary.simpleMessage("沒有幫助"),
    "Chat_feedback_optional": MessageLookupByLibrary.simpleMessage("選填"),
    "Chat_feedback_other": MessageLookupByLibrary.simpleMessage("其他"),
    "Chat_feedback_poor": MessageLookupByLibrary.simpleMessage("1 · 差"),
    "Chat_feedback_quality_score": MessageLookupByLibrary.simpleMessage("質素評分"),
    "Chat_feedback_reason_prompt": MessageLookupByLibrary.simpleMessage(
      "哪些因素影響了您的評分？",
    ),
    "Chat_feedback_reason_required": MessageLookupByLibrary.simpleMessage(
      "請至少選擇一個原因以繼續。",
    ),
    "Chat_feedback_save_failed": MessageLookupByLibrary.simpleMessage(
      "無法儲存意見。請再試一次。",
    ),
    "Chat_feedback_saved": MessageLookupByLibrary.simpleMessage("意見已儲存。"),
    "Chat_feedback_submit": MessageLookupByLibrary.simpleMessage("提交意見"),
    "Chat_feedback_submitted": MessageLookupByLibrary.simpleMessage("意見已提交"),
    "Chat_feedback_title": MessageLookupByLibrary.simpleMessage("評價此回覆"),
    "Chat_feedback_too_verbose": MessageLookupByLibrary.simpleMessage("過於冗長"),
    "Chat_feedback_unclear": MessageLookupByLibrary.simpleMessage("不清晰"),
    "Chat_feedback_update": MessageLookupByLibrary.simpleMessage("更新意見"),
    "Chat_feedback_useful_detail": MessageLookupByLibrary.simpleMessage("細節有用"),
    "Chat_file_count": m20,
    "Chat_files": MessageLookupByLibrary.simpleMessage("檔案"),
    "Chat_find_in_chat": MessageLookupByLibrary.simpleMessage("在對話中尋找"),
    "Chat_folder_name": MessageLookupByLibrary.simpleMessage("資料夾名稱"),
    "Chat_generating_response_stop": MessageLookupByLibrary.simpleMessage(
      "正在生成回覆。停止生成",
    ),
    "Chat_get_response": MessageLookupByLibrary.simpleMessage("取得回覆"),
    "Chat_good_response": MessageLookupByLibrary.simpleMessage("良好回覆"),
    "Chat_image_preview": MessageLookupByLibrary.simpleMessage("圖片預覽"),
    "Chat_image_preview_unavailable": MessageLookupByLibrary.simpleMessage(
      "無法預覽此圖片。",
    ),
    "Chat_jump_to_latest": MessageLookupByLibrary.simpleMessage("跳至最新訊息"),
    "Chat_knowledge": MessageLookupByLibrary.simpleMessage("知識庫"),
    "Chat_knowledge_collection": MessageLookupByLibrary.simpleMessage("知識集合"),
    "Chat_knowledge_file": MessageLookupByLibrary.simpleMessage("知識檔案"),
    "Chat_link_copied": MessageLookupByLibrary.simpleMessage("連結已複製到剪貼簿"),
    "Chat_message_time": m21,
    "Chat_models": MessageLookupByLibrary.simpleMessage("模型"),
    "Chat_more": MessageLookupByLibrary.simpleMessage("更多"),
    "Chat_more_actions": MessageLookupByLibrary.simpleMessage("更多操作"),
    "Chat_move_to_folder": MessageLookupByLibrary.simpleMessage("移至資料夾"),
    "Chat_new_chat": MessageLookupByLibrary.simpleMessage("新增對話"),
    "Chat_new_folder": MessageLookupByLibrary.simpleMessage("新增資料夾"),
    "Chat_no_chats": MessageLookupByLibrary.simpleMessage("尚未有對話"),
    "Chat_no_chats_found": MessageLookupByLibrary.simpleMessage("找不到對話"),
    "Chat_no_folder_chats": MessageLookupByLibrary.simpleMessage("資料夾內沒有對話"),
    "Chat_no_folders": MessageLookupByLibrary.simpleMessage("尚未有資料夾"),
    "Chat_no_knowledge_sources": MessageLookupByLibrary.simpleMessage(
      "找不到知識來源",
    ),
    "Chat_no_matching_chats": MessageLookupByLibrary.simpleMessage("沒有符合的對話"),
    "Chat_open_calculators": MessageLookupByLibrary.simpleMessage("開啟複合材料計算器"),
    "Chat_open_link_failed": MessageLookupByLibrary.simpleMessage("無法開啟此連結。"),
    "Chat_photo_library": MessageLookupByLibrary.simpleMessage("相片圖庫"),
    "Chat_pin": MessageLookupByLibrary.simpleMessage("置頂"),
    "Chat_pinned": MessageLookupByLibrary.simpleMessage("已置頂"),
    "Chat_preview_image": m22,
    "Chat_processing_document": MessageLookupByLibrary.simpleMessage("正在處理文件…"),
    "Chat_processing_failed": MessageLookupByLibrary.simpleMessage("處理失敗"),
    "Chat_processing_failed_detail": m23,
    "Chat_read_file": m24,
    "Chat_refresh_knowledge": MessageLookupByLibrary.simpleMessage("重新整理知識庫"),
    "Chat_regenerate_response": MessageLookupByLibrary.simpleMessage("重新生成回覆"),
    "Chat_remove_attachment": m25,
    "Chat_remove_from_folder": MessageLookupByLibrary.simpleMessage("從資料夾移除"),
    "Chat_rename": MessageLookupByLibrary.simpleMessage("重新命名"),
    "Chat_rename_chat": MessageLookupByLibrary.simpleMessage("重新命名對話"),
    "Chat_replace_draft": MessageLookupByLibrary.simpleMessage("取代草稿"),
    "Chat_replace_draft_message": MessageLookupByLibrary.simpleMessage(
      "以此訊息取代目前尚未傳送的文字？",
    ),
    "Chat_replace_draft_title": MessageLookupByLibrary.simpleMessage("取代草稿？"),
    "Chat_response_interrupted": MessageLookupByLibrary.simpleMessage("回覆已中斷"),
    "Chat_save": MessageLookupByLibrary.simpleMessage("儲存"),
    "Chat_search_all": MessageLookupByLibrary.simpleMessage("全部"),
    "Chat_search_answers": MessageLookupByLibrary.simpleMessage("回答"),
    "Chat_search_assistant": MessageLookupByLibrary.simpleMessage("助手"),
    "Chat_search_chats": MessageLookupByLibrary.simpleMessage("搜尋對話"),
    "Chat_search_clear": MessageLookupByLibrary.simpleMessage("清除搜尋"),
    "Chat_search_copy_excerpt": MessageLookupByLibrary.simpleMessage("複製摘錄"),
    "Chat_search_copy_failed": MessageLookupByLibrary.simpleMessage("無法複製此摘錄。"),
    "Chat_search_empty": MessageLookupByLibrary.simpleMessage("輸入文字以搜尋此對話。"),
    "Chat_search_excerpt_copied": MessageLookupByLibrary.simpleMessage("摘錄已複製"),
    "Chat_search_history_title": m26,
    "Chat_search_knowledge": MessageLookupByLibrary.simpleMessage("搜尋知識庫"),
    "Chat_search_loaded_messages": MessageLookupByLibrary.simpleMessage(
      "搜尋已載入的訊息",
    ),
    "Chat_search_match_count": m27,
    "Chat_search_no_matches": MessageLookupByLibrary.simpleMessage("沒有符合的訊息。"),
    "Chat_search_questions": MessageLookupByLibrary.simpleMessage("問題"),
    "Chat_search_you": MessageLookupByLibrary.simpleMessage("您"),
    "Chat_select_model": MessageLookupByLibrary.simpleMessage("選擇模型"),
    "Chat_send_message": MessageLookupByLibrary.simpleMessage("傳送訊息"),
    "Chat_share": MessageLookupByLibrary.simpleMessage("分享"),
    "Chat_share_chat": MessageLookupByLibrary.simpleMessage("分享對話"),
    "Chat_share_chat_description": MessageLookupByLibrary.simpleMessage(
      "建立連結後傳送的訊息不會被分享。任何取得此連結的人都可以檢視此對話。",
    ),
    "Chat_share_markdown": MessageLookupByLibrary.simpleMessage(
      "以 Markdown 分享",
    ),
    "Chat_share_pdf": MessageLookupByLibrary.simpleMessage("以 PDF 分享"),
    "Chat_sign_in": MessageLookupByLibrary.simpleMessage("登入"),
    "Chat_sign_in_description": MessageLookupByLibrary.simpleMessage(
      "登入以使用對話功能，亦可免登入使用複合材料計算器。",
    ),
    "Chat_sign_in_to_chat": MessageLookupByLibrary.simpleMessage("登入以開始對話"),
    "Chat_start_new_chat_help": MessageLookupByLibrary.simpleMessage(
      "新增對話以開始交談。",
    ),
    "Chat_start_voice_input": MessageLookupByLibrary.simpleMessage("開始語音輸入"),
    "Chat_starter_empty": MessageLookupByLibrary.simpleMessage("在下方輸入問題即可開始。"),
    "Chat_starter_hide_preview": MessageLookupByLibrary.simpleMessage("收起問題"),
    "Chat_starter_preview": MessageLookupByLibrary.simpleMessage("預覽問題"),
    "Chat_starter_review_hint": MessageLookupByLibrary.simpleMessage(
      "先選擇一個起點，傳送前再檢查草稿。",
    ),
    "Chat_starter_use_question": MessageLookupByLibrary.simpleMessage("使用此問題"),
    "Chat_starters_less": MessageLookupByLibrary.simpleMessage("顯示較少"),
    "Chat_starters_more": MessageLookupByLibrary.simpleMessage("查看更多起點"),
    "Chat_stop_generating": MessageLookupByLibrary.simpleMessage("停止生成"),
    "Chat_stop_voice_input": MessageLookupByLibrary.simpleMessage("停止語音輸入"),
    "Chat_suggested_questions": MessageLookupByLibrary.simpleMessage("建議問題"),
    "Chat_task_calculators": MessageLookupByLibrary.simpleMessage("選擇計算器"),
    "Chat_task_failure": MessageLookupByLibrary.simpleMessage("了解失效"),
    "Chat_task_generic": MessageLookupByLibrary.simpleMessage("探索問題"),
    "Chat_task_laminate": MessageLookupByLibrary.simpleMessage("規劃鋪層"),
    "Chat_task_materials": MessageLookupByLibrary.simpleMessage("比較材料"),
    "Chat_task_stiffness": MessageLookupByLibrary.simpleMessage("估算剛度"),
    "Chat_title": MessageLookupByLibrary.simpleMessage("對話"),
    "Chat_undo": MessageLookupByLibrary.simpleMessage("復原"),
    "Chat_unpin": MessageLookupByLibrary.simpleMessage("取消置頂"),
    "Chat_untitled_chat": MessageLookupByLibrary.simpleMessage("未命名對話"),
    "Chat_use_as_draft": MessageLookupByLibrary.simpleMessage("用作草稿"),
    "Chat_voice_unavailable": MessageLookupByLibrary.simpleMessage(
      "無法使用語音輸入。請檢查咪高峰權限。",
    ),
    "Chat_welcome": MessageLookupByLibrary.simpleMessage("歡迎"),
    "Chat_welcome_description": MessageLookupByLibrary.simpleMessage(
      "詢問有關材料、層合板設計、失效分析、製造或工程計算的問題。",
    ),
    "Chat_welcome_name": m28,
    "Chat_working_on": MessageLookupByLibrary.simpleMessage("您正在研究甚麼？"),
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
    "Legacy_data_export": MessageLookupByLibrary.simpleMessage("匯出舊版資料"),
    "Legacy_data_failed": MessageLookupByLibrary.simpleMessage(
      "無法匯出舊版資料，原始資料未有更改。",
    ),
    "Legacy_data_help": MessageLookupByLibrary.simpleMessage(
      "匯出舊版 Mac 應用程式中儲存的所有材料及鋪層資料。備份會保留原始數值及單位，並與新版材料庫分開儲存。",
    ),
    "Legacy_data_saved": MessageLookupByLibrary.simpleMessage(
      "已匯出舊版 SwiftComp 資料。",
    ),
    "Legacy_data_title": MessageLookupByLibrary.simpleMessage(
      "舊版 SwiftComp 資料",
    ),
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
